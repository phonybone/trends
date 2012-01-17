#!/usr/bin/env perl 

# 
# Parse all (or some of) the series.soft files.
# Store info to platform, series, and sample dbs.
# Writes data tables for platforms and samples (not series)
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;
use Devel::Size qw(size total_size);

use Options;
use PhonyBone::FileUtilities qw(warnf dief file_lines);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;
use GEO::Series;
use GEO::Platform;
use GEO::Platform;
use ParseSoft;

# todo:
# update_sample trying to write to bogus file; GEO::Sample->path issue (I think that's the right class)
# find out why not updating GPL96...
#

# GLOBALS:
my $stats={};
our %subrefs=(
	      database=>sub {},
	      series=>\&handle_series,
	      platform=>\&handle_platform,
	      sample=>\&handle_sample
	      );
BEGIN: {
    $ENV{TRENDS_HOME}||='';
    die "environment variable TRENDS_HOME not set or non-existant ($ENV{TRENDS_HOME})\n" 
	unless -d $ENV{TRENDS_HOME};
    Options::use(qw(d q v h fuse=i db_name=s series_dir=s report_overwrites gses=s ignore_table));
    Options::useDefaults(fuse => -1, 
			 db_name=>'geo',
			 series_dir=>"$ENV{TRENDS_HOME}/data/GEO/series",
			 gses=>[],
	);
    Options::get();
    die Options::usage() if $options{h};
    die "options -q and -d are mutually exclusive\n" if $options{q} && $options{d};
    die "options -q and -v are mutually exclusive\n" if $options{q} && $options{v};
    $ENV{DEBUG} = 1 if $options{d};
    GEO->db_name($options{db_name});
    warnf "writing to db %s\n", $options{db_name} if $ENV{DEBUG};
    warn "ignoring data tables\n" if $options{ignore_table};
}

sub main {
    warn "$0: ", join(' ', @_), "\n" if $ENV{DEBUG};

    # get a list of all the GSE_family.soft files (might be gzipped)
    my @soft_files=get_soft_files();
    my $fuse=$options{fuse};
    warnf "processing %d files (fuse=$fuse)\n", scalar @soft_files;

    # parse each soft file
    foreach my $soft_file (@soft_files) {
	warn "parsing $soft_file...\n";
	parse_soft($soft_file);
	last if --$fuse==0;
    }
    
    warn "stats: ",Dumper($stats);
}

sub get_soft_files {
    my @files=();

    # if $options{gses} present, use that
    if ($options{gses}) {
	my @gses=Options::file_or_list('gses');
	@files=map {sprintf "%s/%s/%s/%s_family.soft", GEO->data_dir, GEO::Series->subdir, $_, $_} @gses;
	return wantarray? @files:\@files;
    }

    # Look for all unparsed series.soft and series.soft.gz files under $options{series_dir}:
    my $series_dir=$options{series_dir};
    warn "looking for files under $series_dir...\n";
    my $find_output=`find $series_dir -name '*family.soft'`;
    push @files, split(/\n/, $find_output);

    $find_output=`find $series_dir -name '*family.soft.gz'`;
    push @files, split(/\n/, $find_output);
    
    wantarray? @files:\@files;
}

########################################################################

sub parse_soft {
    my ($filename)=@_;
    warn "parsing $filename...\n" if $ENV{DEBUG};
    $filename=gunzip($filename) or return;
    if (already_processed($filename)) {
	warn "already processed $filename, skipping\n";
	return;
    }	

    my $ps=new ParseSoft(filename=>$filename, ignore_table=>$options{ignore_table});
    while (1) {
	my $record;
	eval { $record=$ps->next };
	warn "error parsing $filename: $@\n" if $@;
	last unless $record;

	my $class=ref $record;
	my $subref=$subrefs{$class} or die "Don't know how to handle '$class', bye";
	$subref->($record);
    }
}




sub gunzip {
    my ($filename)=@_;

    # check if $filename already unzipped:
    $filename=~s/\.gz$//;	# remove .gz if exists
    return $filename if -r $filename;

    $filename.='.gz' unless $filename=~/\.gz$/;	# append '.gz' if needed
    my $rc=system('gunzip',$filename) if -r $filename;	# gunzip filename if it exists
    if ($rc) {
	warn "error during 'gunzip $filename'\n";
	return undef;
    }
    $filename=~s/\.gz$//;	# remove .gz
    $filename;
}

sub already_processed {
    my ($filename)=@_;
    
    # get gse and Series:
    $filename=~/GSE\d+/ or die "bad filename: $filename";
    my $gse=$&;
    my $series=GEO->factory($gse);
    return undef unless $series->_id; 

    # check db for samples in db:
    my $sample_ids=$series->sample_ids or return undef;
    foreach my $sample_id (@$sample_ids) {
	my $sample=GEO->factory($sample_id);
	return undef unless $sample->_id;
	return undef unless -e $sample->data_table_file
    }

    return $options{ignore_table}; # this goes last because we have to check all the samples if $options{ignore_table} not set.
}

########################################################################

sub series {
    my ($record)=@_;

    $record->{sample_ids}=$record->{sample_id};	# this sux, but what to do...?
    delete $record->{sample_id};
    unless (ref $record->{sample_ids} eq 'ARRAY') {
	$record->{sample_ids}=[$record->{sample_ids}];
    }

    my $series=update_record($record);
    foreach my $sample_id (@{$series->sample_ids}) {
	GEO::Sample->new($sample_id)->tie_to_geo($series, 'series_ids');
      }
    $series->add_to_word2geo;
}

# update the database and return a GEO object based on $record
sub update_record {
    my ($record)=@_;
    my $geo_id=$record->{geo_id} or do {
	$stats->{missing_geo_id}++;
	return;
    };

    my $geo=GEO->factory($geo_id);
    $geo->hash_assign(%$record); # ignores all keys starting with '_'
    $geo->status('downloaded') if $geo->can('status');
    $geo->update({upsert=>1});
    my $class=ref $geo;
    $class=~s/^GEO:://;
    $stats->{"n_${class}_updated"}++;
    warnf "updated: %s", $geo if $ENV{DEBUG} && $options{v};

    # add fields starting with '_' back in to geo object:
    foreach my $k (grep /^_/, keys %$record) {
	$geo->{$k}=$record->{$k};
    }

    $geo;
}

sub handle_sample {
    my ($record)=@_;
    my $sample=update_record($record);
    $sample->write_table unless $options{ignore_table};
}
    
sub handle_series {
    my ($record)=@_;
    my $series=update_record($record);
    # no table to worry about
}
    

sub handle_platform {
    my ($record)=@_;
    my $platform=update_record($record);
    
    # If record and data file already exist, just ignore this:
    if ($platform->_id && -e $platform->data_table_file) {
	warnf "platform %s already in db and data.table exists, skipping\n", $platform->geo_id;
    } else {
	$platform->write_table unless $options{ignore_table};
    }
}

main(@ARGV);
