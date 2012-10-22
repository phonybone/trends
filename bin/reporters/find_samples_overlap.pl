#!/usr/bin/perl

#
# find samples that are referenced by both series and datasets
#

use strict;
use warnings;
use MongoDB;
use Data::Dumper;
use Carp;

use Options;
use PhonyBone::FileUtilities qw(warnf);
use PhonyBone::ListUtilities qw(intersection);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    # get all raw sample ids
    my @raw_samples=map {$_->{geo_id}} GEO::RawSample->get_mongo_records({}, {geo_id=>1});
    warnf "got %d raw samples\n", scalar @raw_samples;
    warnf "first raw sample: %s\n", Dumper($raw_samples[0]);

    # get all series data ids (ie, samples associated with series)
    my @series_samples=map {$_->{geo_id}} GEO::SeriesData->get_mongo_records({}, {geo_id=>1});
    warnf "got %d series samples\n", scalar @series_samples;
    warnf "first series sample: %s\n", Dumper($series_samples[0]);

    my $common_ids=intersection(\@raw_samples, \@series_samples);
    warnf "got %d ids in common\n", scalar @$common_ids;
    warn Dumper($common_ids) if $ENV{DEBUG};
}

main(@ARGV);
