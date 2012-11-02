#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin";
use Cwd 'abs_path';
use lib abs_path("$ENV{TRENDS_HOME}/lib");

use Options;			
use TestHasSubsets;		# derived from PhonyBone::TestCase


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $tc=new TestHasSubsets(class=>'GEO::Dataset');
    $tc->test_compiles();
    $tc->test_subsets('GDS2381', 16);
    $tc->test_subsets('GDS2321', 2);

    $tc->test_subset_phenos('GDS2381');
    $tc->test_subset_phenos('GDS2321');
    $tc->test_subset_phenos('GSM385338');

    $tc->test_subsets('GDS3567', 0);
    $tc->test_subsets('GSM385338', 0);

    $tc->test_gds_gsm_pair('GDS3567', 'GSM385338');
}



main(@ARGV);

