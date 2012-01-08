#!/usr/bin/env perl 

#
# map the dataset (gds) to series (gse) in the series db
# using the dataset db.
# THIS SCRIPT IS NOW OBSOLETE; USE parse_dataset_soft.pl instead.
#


use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::Series;
use GEO::Dataset;

BEGIN: {
  Options::use(qw(d q v h fuse=i db_name=s));
    Options::useDefaults(fuse => -1, db_name=>'geo');
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO->db_name($options{db_name});
}


sub main {
    die "OBSOLETE! Use parse_soft.pl instead!\n";
    # collect all gds.reference_series in a hash:
    my @gds_recs=GEO::Dataset->get_mongo_records({}, {geo_id=>1, reference_series=>1});
    warnf "%d dataset records\n", scalar @gds_recs;

    # create hash map: k=gds->id, v=gse->id
    my %gds2gse=map {($_->{geo_id}, $_->{reference_series})} @gds_recs;
    warnf "%d gds->gse mappings\n", scalar keys %gds2gse;

    my $stats={
	n_orphans=>0,		# no series for the given dataset
	n_uptodate=>0,		# number of series already pointing back to dataset
	n_updated=>0,		# number of series fixed
	n_multis=>0,		# number of series that have multiple datasets (hopefully 0)
    };

    my $fuse=$options{fuse};

    while (my ($gds, $gse)=each %gds2gse) {
	my $series=new GEO::Series($gse); # loads from mongo if geo_id is set, which it is

	# check to see if series exists: (might not be downloaded (yet))
	if (! defined $series->_id || ! -r $series->path) {
	    warnf "$gse: no such series\n";
	    $stats->{n_orphans}++;

	} elsif (defined $series->dataset_id) {
	    if ($series->dataset_id eq $gds) {
		$stats->{n_uptodate}++;
	    } else {
		warnf "additional dataset for $gse: stored=%s, ignored=$gds\n", $series->dataset_id;
		$stats->{n_multis}++;
	    }

	} else {
	    $series->dataset_id($gds);
	    my $report=$series->update({upsert=>1, safe=>1});
	    warnf "%s: report=%s", $series->geo_id, Dumper($report) if $ENV{DEBUG};
	    $stats->{n_updated}++;
	}

	last if --$fuse==0;
    }
    warn "stats: ",Dumper($stats);
}

main(@ARGV);

