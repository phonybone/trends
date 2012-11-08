#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib "$Bin";
use lib "$ENV{TRENDS_HOME}/lib";

use Options;			
#use SomeTestcase;		# derived from PhonyBone::TestCase

our $class='GEO';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $series=GEO->factory('GSE803');
    warn Dumper($series->subset_phenos);
}

main(@ARGV);

