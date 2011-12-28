#!/usr/bin/env perl 

#
# rename the series->status field to series->isb_status so that it doesn't conflict with
# geo_status (from the series.soft files)
# Note: you can't run this file once you've loaded the .soft files; otherwise everything'll be buggered.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use GEO::Series;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $series_col=GEO::Series->mongo;
    my $stats={};

    # for each series in database:
    my @series_recs=GEO::Series->get_mongo_records({});	# tike OLE the records!
    $stats->{total}=scalar @series_recs;
    my $fuse=$options{fuse};

    foreach my $r (@series_recs) {
	warnf "%s: status was %s\n", $r->{geo_id}, ($r->{status} // '<undef>');
	next unless $r->{geo_id}; # should never happen, but whatevs
	next unless $r->{status};
	$r->{isb_status}=$r->{status};
	delete $r->{status};
	unless ($ENV{DEBUG}) {
	    $series_col->update({geo_id=>$r->{geo_id}}, $r);
	    $stats->{n_updated}++;
	}
	last if --$fuse==0;
    }
    warn Dumper($stats);
}


main(@ARGV);

