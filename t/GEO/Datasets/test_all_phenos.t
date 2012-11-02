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
use GEO;
use Options;			
use TestAllPhenos;		# derived from PhonyBone::TestCase

our $class='GEO::Dataset';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $tc=new TestAllPhenos(class=>$class);
    $tc->test_compiles();
    $tc->test_all_phenos('GDS2381');
    $tc->test_all_phenos('GDS2321');
}

main(@ARGV);

