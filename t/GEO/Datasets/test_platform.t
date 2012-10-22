#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../../lib";

our $class='GEO::Dataset';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    
    my $geo_id='GDS2759';
    my $ds=GEO::Dataset->new(geo_id=>$geo_id);
    $ds->get_mongo_record;

    my $expected_platform='GPL2507';
    is($ds->platform, $expected_platform, "got '$expected_platform' for series $geo_id");
}

main(@ARGV);
