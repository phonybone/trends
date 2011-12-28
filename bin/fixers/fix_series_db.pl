#!/usr/bin/env perl 

#
# Repair the series db based on information contained in the series data subdir.
# But just doing so won't restore the meta date found in series.csv...
# This script is OBSOLETE
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

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    # for each series in database:
    my @series_recs=GEO::Series->get_mongo_records({});	# tike OLE the records!
    foreach my $r (@series_recs) {

	# create a series object by loading from db
	delete $r->{samples};
	my $series=GEO::Series->new(%$r);

	# replace the {samples} field with list obtained from disk
	my $gsms=$series->samples_in_dir(); 
	warnf "%s: gsms are %s\n", $series->geo_id, join(', ', @{$series->samples});

	# store the record back to the db
	$series->update;
    }
}


main(@ARGV);

