#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use lib "$ENV{TRENDS_HOME}/lib";
use FindBin qw($Bin);
use lib "$Bin";

use Options;			
use TestPhenos;		# derived from PhonyBone::TestCase

our $class='GEO::Sample';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $tc=new TestPhenos(class=>$class);
    $tc->test_compiles();
    $tc->test_pheno_hash('GSM132638');
    $tc->test_subset_phenos('GSM30418');
}

main(@ARGV);

