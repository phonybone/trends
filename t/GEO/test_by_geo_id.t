#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf);
use PhonyBone::TimeUtilities qw(tlm);
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../lib";

our $class='GEO';
use TestGeoIdSorting;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $tc=new TestGeoIdSorting(class=>$class);
    $tc->test_compiles();
    $tc->test_sort_order();
}


main(@ARGV);





