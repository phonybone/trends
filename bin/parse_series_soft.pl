#!/usr/bin/env perl 

# 
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
  Options::use(qw(d q v h fuse=i db_name=s series_dir=s report_overwrites gses=s));
    Options::useDefaults(fuse => -1, 
			 db_name=>'geo',
			 series_dir=>'/proj/price1/vcassen/trends/data/GEO/series',
			 gses=>[],
			 );
    Options::get();
    die Options::usage() if $options{h};
    die "options -q and -d are mutually exclusive\n" if $options{q} && $options{d};
    die "options -q and -v are mutually exclusive\n" if $options{q} && $options{v};
    $ENV{DEBUG} = 1 if $options{d};
    $options{v}=1 if $options{d};
    GEO->db_name($options{db_name});
    warnf "writing to db %s\n", $options{db_name} if $ENV{DEBUG};
}

sub main {
    # get a list of all the GSE_family.soft files (might be gzipped)
    my @soft_files=get_soft_files();
    warnf "processing %d files\n", scalar @soft_files;

    # parse each soft file
    my $fuse=$options{fuse};
    foreach my $soft_file (@soft_files) {
	parse_soft($soft_file);
	last if --$fuse==0;
    }
    
    warn "stats: ",Dumper($stats);
}

sub get_soft_files {
    my @files=();

    # if $options{gses} present, use that
    if (my $gse_list=$options{gses}) { # can either be command-line list or name of file containing "\n"-separated list
	my @gses=();
	if (-r $gse_list->[0]) {
	    @gses=map {chomp; $_} file_lines($gse_list->[0]);
	} elsif (ref $gse_list eq 'ARRAY') {
	    @gses=@$gse_list;
	} else {
	    die "Don't know how to convert to list of gse's: ", Dumper($gse_list);
	}
	@files=map {GEO::Series->new($_)->softpath} @gses;
	return wantarray? @files:\@files;
    }

    # Look for all unparsed series.soft and series.soft.gz files under $options{series_dir}:
    my $series_dir=$options{series_dir};
    warn "looking for files under $series_dir...\n";
    my $find_output=`find $series_dir -name '*family.soft'`;
    push @files, split(/\n/, $find_output);

    # temporarily comment these out until fully debugged
    $find_output=`find $series_dir -name '*family.soft.gz'`;
    push @files, split(/\n/, $find_output);
    
    wantarray? @files:\@files;
}

########################################################################

sub parse_soft_old {
    my ($filename)=@_;
    warn "parsing $filename...\n" if $ENV{DEBUG};
    $filename=gunzip($filename);		# handles messy logic

    if (already_processed($filename)) {
	warn "already processed $filename, skipping\n";
	return;
    }	

    my $ps=new ParseSoft($filename);
    my @records=$ps->parse;
    warnf "%s: got %d records\n", $filename, scalar @records;

    foreach my $record (@records) {
	my $class=ref $record;
	my $subref=$subrefs{$class} or die "Don't know how to handle '$class', bye";
	$subref->($record);
    }
}

sub parse_soft {
    my ($filename)=@_;
    warn "parsing $filename...\n" if $ENV{DEBUG};
    $filename=gunzip($filename) or return;

    if (already_processed($filename)) {
	warn "already processed $filename, skipping\n";
	return;
    }	

    my $ps=new ParseSoft($filename);
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

    return 1;
}

########################################################################

sub handle_series {
    my ($record)=@_;
    $record->{sample_ids}=$record->{sample_id};
    delete $record->{sample_id};
    update_record($record, GEO::Series->mongo);
}

sub update_record {
    my ($record, $mongo)=@_;

    # see if an old record exists:
    my $geo_id=$record->{geo_accession} or die "no geo_id by way of geo_accession in ",Dumper($record);

    my $old_rec=$mongo->find_one({geo_id=>$geo_id});
    if ($old_rec) {
	$stats->{updated}++;
    } else {
	$old_rec={geo_id=>$geo_id};
	$stats->{inserted}++;
    }

    # copy new record into old, with warnings:
    while (my ($k,$v)=each %$record) {
	if ($old_rec->{$k}) {	# check for overwrites and attempt to write a useful warning message if found:
	    if ($options{report_overwrites} && !ref $old_rec->{$k} && !ref $record->{$k}) {
		if ($old_rec->{$k} ne $record->{$k}) {
		    warnf "%s: overwriting old '%s' with '%s'\n", $geo_id, $k, (ref $v || $v);
		} 
	    } else {
		#warnf "%s->{%s}: non-scalar field(s) might differ\n", $geo_id, $k;
	    }
	}
	$old_rec->{$k}=$v;
    }
    $old_rec->{isb_status}='downloaded';

    # insert/update the record:
    eval {
	warnf "updating $geo_id...\n" if $ENV{DEBUG};

	# update, but exclude __table:
	my $__table=$record->{__table};
	$record->{__table}=undef; # You'd think delete would work, but it doesn't seem to, as far as MongoDB is concerned
	$mongo->update({geo_id=>$geo_id}, $old_rec, {upsert=>1, safe=>1});
	$record->{__table}=$__table;

	$stats->{success}++;
    };
    if ($@) {
	warnf("%s: update error: $@\n", $geo_id);
	$stats->{errors}++;
    }
}

sub handle_sample {
    my ($record)=@_;
    GEO::SeriesData->new($record->{geo_accession})->write_table($record->{__table});
    delete $record->{__table};
    update_record($record, GEO::SeriesData->mongo);
}
    

sub handle_platform {
    my ($record)=@_;
    my $mongo=GEO::Platform->mongo;
    
    # If record and data file already exist, just ignore this:
    my $geo_id=$record->{geo_accession} or die "no geo_id by way of geo_accession in ",Dumper($record);
    my $platform=new GEO::Platform($geo_id);
    if ($platform->_id && -e $platform->data_table_file) {
	warnf "platform %s already in db and data.table exists, skipping\n", $geo_id;
	return;
    }

    GEO::Platform->new($record->{geo_accession})->write_table($record->{__table});
    delete $record->{__table};
    update_record($record, GEO::Platform->mongo);
    
    

}

main();
