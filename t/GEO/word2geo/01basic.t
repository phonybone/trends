#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin");
use lib "$ENV{TRENDS_HOME}/lib";

use Options;			
use TestBasic;		# derived from TestGEO

our $class='GEO::word2geo';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $tc=new TestBasic(class=>$class);
    $tc->test_compiles();
}

main(@ARGV);

