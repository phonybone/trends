#!/usr/bin/env perl 

# The sample db has entries for both series_id and series_ids.
# Combine these two fields under series_ids.

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use GEO::Sample;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    # get all samples that define series_id:
    my @records=GEO::Sample->get_mongo_records({series_id=> {'$ne'=>undef}});
    warnf "got %d samples that define series_id\n", scalar @records;

    my $stats={};
    my $fuse=$options{fuse};
    foreach my $record (@records) {
	my $sample=GEO::Sample->new(%$record);
	$sample->hash_assign(%$record);
	my $series_id=$sample->{series_id};
	my $geo_id=$sample->geo_id;
	if (ref $series_id) {
	    warn "$geo_id: '$series_id': not a scalar\n";
	    $stats->{non_scalar}++;
	    next;
	}
	$sample->append('series_ids', $series_id, {unique=>1});
	delete $sample->{series_id};
	$sample->update;
	$stats->{updated}++;
	warn "$geo_id updated\n";
	last if --$fuse==0;
    }
    warn "stats: ",Dumper($stats);
}

main(@ARGV);

