#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin";
use lib "$ENV{TRENDS_HOME}/lib";

use Options;			
use TestHasPhenos;		# derived from PhonyBone::TestCase

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $tc=new TestHasPhenos(class=>'GEO::Dataset');
    $tc->test_compiles();
    $tc->show_phenos('GDS2381'); # this (currently) shows five phenos; all from subsets?
    $tc->show_phenos('GDS2321');
    $tc->show_phenos('GSM132638');
    $tc->show_phenos('GSM32638');
    $tc->show_phenos('GSE14777');

    $tc->test_gsm_phenos_in_gds('GDS2381', 'GSM132638');
}

main(@ARGV);

