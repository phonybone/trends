#!/usr/bin/env perl 

#
# Download GEO "series" data from NCBI.
# "series" data consists of series records and attactched raw_sample data.  A series is really nothing
# more than a container for a group of raw_sample data files plus metadata.
#
# This script stores the raw_sample files (geo_id=GSMxxxx) on disk (compressed) and builds
# two MongoDB collections in the 'geo' database: 'series' and 'raw_samples'.  Its input
# is a file 'series.csv' containing a list of geo series records obtained from GEO's 
# website.  This was the result of a search query for human data. (So all the data
# used here is human).
#
# -repair_db avoids downloading tars from NCBI, and instead attempts to set the contents of the db
# soley from what exists in the series directories.  -repair_db REMOVES ALL ENTRIES FROM THE SERIES
# AND RAW_SAMPLES TABLES BEFOREHAND!
#
#
# TODO: 
# - fix up the database since you deleted it by accident, dumbass.
# - add complete raw_sample records to db
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;

use Options;
use PhonyBone::FileUtilities qw(warnf dief file_lines is_empty);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::Dataset;
use GEO::Series;

# GLOBALS:
my $db;
my $connection;
my @ARGV_ORIG;
my $stats={};

BEGIN: {
    @ARGV_ORIG=@ARGV;
    Options::use(qw(d q v h series_csv=s fuse=i delay=i dst_dir=s ftp_link=s ftp_base=s keep_tars 
		    filter_gses=s use_datasets repair_db db_name=s));
    Options::useDefaults(fuse => -1, delay => 5,
			 series_csv=>'/proj/price1/vcassen/trends/data/GEO/series.hs.csv',
			 db_name=>'geo',
			 ftp_link=>'ftp.ncbi.nih.gov',
			 ftp_base=>'pub/geo/DATA/supplementary/series',
			 dst_dir=>'/proj/price1/vcassen/trends/data/GEO/series',
			 max_limit=>'10_000' # measured in GB
			 );
    Options::get();
    die Options::usage() if $options{h};
    die "options -q and -d are mutually exclusive\n" if $options{q} && $options{d};
    die "options -q and -v are mutually exclusive\n" if $options{q} && $options{v};
    $ENV{DEBUG} = 1 if $options{d};
    $options{v}=1 if $options{d};
    $options{delay}=0 if $options{repair_db};
    GEO->db_name($options{db_name});
}

sub main {
    warn join(' ', $0, @ARGV_ORIG),"\n" unless $options{q}; # for debugging purposes
    my $mongos=get_mongos();
    my $series_fn=$options{series_csv} or die Options::usage();

    my $ftp_base_dir=$options{ftp_base};

    # get GSE filter:
    my %filter=get_filter();

    # make and cd to $dst_dir:
    my $dst_dir=$options{dst_dir};
    mkdir $dst_dir unless -d $dst_dir;

    my $fuse=$options{fuse};
    open (SERIES,$series_fn) or die "Can't open $series_fn: $!\n";
    while (<SERIES>) {
	chomp;
	next unless /homo sapiens/i; # must be human
#	next unless m|ftp://|;	# must list an ftp site

	#  split line, build $dst_dir, init $record, and skip if it doesn't pass the filter:
	my ($GSE, $title, $series_type, $taxonomy, $n_samples, $datasets, $supp_types, $supp_links, $contact, $rel_date)=split/,/; # fixme: commas in date
	next if $options{filter_gses} && !$filter{$GSE}; # allows for specific GSEs only to be downloaded/processed
	warn "\n$GSE\n" if $options{v};

        # load record from mongo_db if able to:
	my $series=get_series($GSE, $title, $series_type, $taxonomy, $n_samples, $datasets, $supp_types, $supp_links, $contact, $rel_date) 
	    or next;
	next if ! -d $series->path && $options{repair_db};

	eval {
	    # Download and unpack the series .tar file:
	    my $dst_tar="$dst_dir/$GSE/${GSE}_RAW.tar";
	    unless (-r $dst_tar || $options{repair_db}) { # happens when (ahem) records are erroneously (cough) deleted from db
		$series->fetch_ncbi;
		warn "$GSE: tarfile fetched and unpacked\n" unless $options{q}; # use disk count
	    }
	    next unless -r $series->tarfile || $options{repair_db};

	    # acquire and assign list of samples:
	    my $sample_ids=$series->sample_ids_in_dir;
	    $series->sample_ids($sample_ids);
	    warnf "%s: %d samples", $series->geo_id, scalar @$sample_ids;
	    
	    # Insert records:
	    $series->status('downloaded');
	    insert_series($series);
	    insert_samples($series);

	    $fuse-=1;
	}; 

	if ($@) {
	    warn "$@\n" unless $options{q};
	    $series->status("error: $@");
	    $series->update({upsert=>1});
	    $stats->{errors}++;
	}
	warnf("%s: status=%s\n", $series->geo_id, $series->status) unless $options{q};

	# if we are doing specific GSEs, remove each GSE from the filter as it's processed; quit if we're out of GSEs
	if ($options{filter_gses}) {
	    delete $filter{$GSE};
	    last unless keys %filter;
	}

	# If we're running out of disk space, quit:
	last if percent_disk_full($dst_dir) > 80;
	last if $fuse==0;	# down here so we can get report on diskspace, above
	sleep $options{delay} if $options{delay};		# be nice to NCBI's servers
    }
    close SERIES;
    warn "Stats:\n",Dumper($stats);
    if (keys %filter && !$options{q}) {
	warnf "%d leftover GSEs: ",scalar keys %filter;
    }
}

#-----------------------------------------------------------------------
# This is wrong
sub get_series {
    my ($GSE, $title, $series_type, $taxonomy, $n_samples, $datasets, $supp_types, $supp_links, $contact, $rel_date)=@_;

    my $series=GEO::Series->new(geo_id=>$GSE); 
    if (defined $series->status) {
	return undef if $series->status eq 'downloaded' || $series->status=~/^error/i;
    }

    if (defined $series->status) {
	$series->delete if $options{repair_db};
    } else {
	# initialize $series from series.csv:
	$series->hash_assign(geo_id=>$GSE, title=>$title, series_type=>$series_type, organism=>$taxonomy, author=>$contact, date=>$rel_date, samples=>[]);
    }
    $series;
}

sub insert_series {
    my ($series)=@_;
    my $status=is_empty($series->path)? 'empty' : 'downloaded'; # only happens during $options{repair_db} (I think)
    $series->status($status);
    $series->update({upsert=>1});
    $stats->{$status}++;
}


sub insert_samples {
    my ($series)=@_;
    foreach my $sample_file ($series->samples_in_dir) {
	$sample_file=~/GSM\d+/;
	my $sample_id=$&;
	my $sample=GEO->factory($sample_id);
	if (ref $sample eq 'GEO::Sample') { # as opposed to GEO::RawSample
	    warnf "%s: sample %s is %s, skipping", $series->geo_id, $sample_id, ref $sample_id;
	    next;
	}
	confess "can't construct sample from '$sample_id'???" unless $sample;
	$sample->path_raw_data(join('/', GEO->data_dir, $series->subdir, $series->geo_id, $sample_file)); # possibly overwrites old path

	my $series_ids=$sample->series_ids;
	push @$series_ids, $series->geo_id;
	$sample->series_ids($series_ids);
	$stats->{n_samples}++ unless $sample->_id; # only count once
	$sample->update({upsert=>1});
    }
}


########################################################################

sub get_mongo {
    my ($db_name, $coll_name)=@_;
    $connection=MongoDB::Connection->new;
    $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $collection;
}

# return a hash[ref] of the mongo collections of interest
sub get_mongos {
    my %collections;
    $collections{series}=get_mongo($options{db_name},'series');
    $collections{series}->ensure_index({geo_id=>1},{unique=>1});

    $collections{raw_samples}=get_mongo($options{db_name},'raw_samples');
    $collections{raw_samples}->ensure_index({geo_id=>1},{unique=>1});
    wantarray? %collections : \%collections;
}


# return a hash[ref] where the keys are the GSEs we want to process
# obtain list from:
#   $options{filter_gses} (can either be command-line list of file containing gses)
#   $options{use_datasets} (use GSEs stored in GDS (datasets) db
# k=$GSE, v=1
# returns a hash[ref], and not a list, so that removals from list are O(1)
sub get_filter {
    my (%filter, $filter_option);
    if (-r $options{filter_gses}) {	# if -filter_gses provides filename
	my @gses=map {/GSE\d+/; $&} file_lines($options{filter_gses});
	do {$filter{$_}=1} for @gses;

    } elsif ($options{filter_gses} eq 'use_datasets') {
	my @records=GEO::Dataset->get_mongo_records({}, {_id=>0, reference_series=>1});
	foreach my $r (@records) {
	    $filter{$r->{reference_series}}=1;
	}
	$options{filter_gses}=1;
	
    } else {		# assume -filter_gses provides a list of gses
	do {$filter{$_}=1} for split(/,/, $options{filter_gses});
    }
    warnf("%d gses in filter\n", scalar keys %filter) if $ENV{DEBUG};
    wantarray? %filter:\%filter;
}

########################################################################

sub percent_disk_full {
    my ($dst_dir)=@_;
    my @lines=split(/\n/, `df -h $dst_dir`);
    my $percent=(split(/\s+/, $lines[1]))[4];
    $percent=~s/[^\d]//g;
    warn "disk ${percent}\% full\n" unless $options{q};
    $percent;
}


main();
