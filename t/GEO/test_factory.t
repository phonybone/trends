#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../../lib");
use lib "$Bin";
our $class='GEO';
use TestFactory;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $tc=new TestFactory(class=>$class);
    $tc->test_compiles();
    $tc->test_geo($_) for qw(GDS2381_1 GDS2381 GSE28230 GSM11703 GSM117646);
}

main(@ARGV);

