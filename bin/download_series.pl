#!/usr/bin/env perl 


use strict;
use warnings;
use Carp;
use Data::Dumper;

use Options;
use PhonyBone::FileUtilities qw(warnf dief file_lines);
use PhonyBone::ListUtilities qw(equal_lists);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::Dataset;
use GEO::Series;

use FindBin;
use lib "$FindBin::Bin/../lib";

# GLOBALS:
my $db;
my $connection;
my @ARGV_ORIG;
my $stats={};

BEGIN: {
    @ARGV_ORIG=@ARGV;
    Options::use(qw(d q v h fuse=i delay=i dst_dir=s ftp_link=s ftp_base=s keep_tars db_name=s overwrite filter_gses=s));

    Options::useDefaults(fuse => -1, delay => 5,
			 db_name=>'geo',
			 ftp_link=>'ftp.ncbi.nih.gov',
			 ftp_base=>'pub/geo/DATA/supplementary/series',
			 dst_dir=>'/proj/price1/vcassen/trends/data/GEO/series',
			 );
    Options::get();
    die Options::usage() if $options{h};
    die "options -q and -d are mutually exclusive\n" if $options{q} && $options{d};
    die "options -q and -v are mutually exclusive\n" if $options{q} && $options{v};
    $ENV{DEBUG} = 1 if $options{d};
    $options{v}=1 if $options{d};
    GEO->db_name($options{db_name});
}

sub main {
    warn join(' ', $0, @ARGV_ORIG),"\n" unless $options{q}; # for debugging purposes
    my $series_fn=$ARGV[0] or die "usage: parse_series [opts] <series.csv>\n";

    my $ftp_base_dir=$options{ftp_base};

    # get gse filter:
    my %filter=get_filter();
    warnf("%d gses in filter\n", scalar keys %filter);

    # make and cd to $dst_dir:
    my $dst_dir=$options{dst_dir};
    mkdir $dst_dir unless -d $dst_dir;

    my $fuse=$options{fuse};
    open (SERIES,$series_fn) or die "Can't open $series_fn: $!\n";
    while (my $line=<SERIES>) {
	chomp $line;
	next unless $line=~/homo sapiens/i; # must be human
	my $series=get_series($line);
	my $GSE=$series->geo_id;

	next if skip($series, \%filter);

	eval {
	    warn "fetching $GSE...\n";
	    $series->fetch_ncbi;
	};
	if ($@) {
	    warnf("%s: %s\n", $series->geo_id, $@);
	    $series->status('error');
	    $series->error($@);
	} else {
	    warnf("%s: downloaded ok\n", $GSE) unless $@;
	    $series->status('downloaded');
	}
	$series->update({upsert=>1});
	
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
# Return a series object based on the contents of a $line from the series.csv file:
sub get_series {
    my ($line)=@_;
    my ($GSE, $title, $series_type, $taxonomy, $n_samples, $datasets, $supp_types, $supp_links, $contact, $rel_date)=split(/,/, $line);

    my $series=GEO::Series->new(geo_id=>$GSE); 
    $series->hash_assign(title=>$title, series_type=>$series_type, organism=>$taxonomy, author=>$contact, date=>$rel_date, samples=>[]);
}

# determine if a gse should be skipped:
# 1. if -filter_gses was present and gse does not pass filter
# 2. if the series' tarball already exists on disk and -force not given
# 3. if $series->{status} matches /^error/ and -force not given
# 4. if $series->{sample_ids} (in record) matches $series->sample_ids_in_dir, and neither are 0 (implying the tarfile was downloaded and then deleted)
sub skip {
    my ($series, $filter)=@_;
    my $GSE=$series->geo_id;
    if ($options{filter_gses} && !$filter->{$GSE}) { # allows for specific GSEs only to be downloaded/processed
	warnf("%s: didn't pass filter\n", $GSE) if $ENV{DEBUG};
	return 1;
    }
    if (-r $series->tarpath && !$options{force}) { # generally won't happen  unless -keep_tars was used previously
	warnf("%s: tarpath readable and force not in effect (%s)\n", $GSE, $series->tarpath) if $ENV{DEBUG};
	return 1;
    }
    
    if (defined $series->status && $series->status =~ /^error/ && !$options{force}) {
	warnf("%s: status set to error and force not in effect\n", $GSE) if $ENV{DEBUG};
	return 1;
    }

    if (defined $series->sample_ids && 
	scalar @{$series->sample_ids} > 0 &&
	equal_lists($series->sample_ids, $series->sample_ids_in_dir)) { # this can happen for empty dirs...
	warnf("%s: sample_ids match disk sample ids (%d samples)\n", $GSE, scalar @{$series->sample_ids}) if $ENV{DEBUG};
	return 1;
    }
    undef;
}

########################################################################


# return a hash[ref] where the keys are the GSEs we want to process
# obtain list from:
#   $options{filter_gses} (can either be command-line list of file containing gses)
#   $options{use_datasets} (use GSEs stored in GDS (datasets) db
# k=$GSE, v=1
# returns a hash[ref], and not a list, so that removals from list are O(1)
sub get_filter {
    my %filter;
    if ($options{filter_gses}) {
	if (-r $options{filter_gses}) {	# if -filter_gses provides filename
	    my @gses=map {/GSE\d+/; $&} file_lines($options{filter_gses});
	    do {$filter{$_}=1} for @gses;
	} else {		# assume -filter_gses provides a list of gses
	    do {$filter{$_}=1} for split(/,/, $options{filter_gses});
	}
    } elsif ($options{use_datasets}) {
	my @records=GEO::Dataset->get_mongo_records({}, {_id=>0, reference_series=>1});
	foreach my $r (@records) {
	    $filter{$r->{reference_series}}=1;
	}
	$options{filter_gses}=1;
    }
    warnf("%d gses in filter\n", scalar keys %filter) if $options{d};
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
