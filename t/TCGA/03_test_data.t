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
our $class='TCGA';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    test_data($class);
}

sub test_data {
    my ($class)=@_;
    my ($type,$id)=('gbm',0);
    my $tcga=$class->new($type,$id);
    my $data=$tcga->exp_data;
    cmp_ok($data->{$_->[0]}, '==', $_->[1], $_->[0]) for (['PNMA1', 1.293],
						    ['STK16',0.7752],
						    ['SYN3',0.0986],
						    ['LARP7',-1.15992857142857],
						    ['GDPD5',-0.8753],
						    ['MAT2A',-1.05626666666667]);
}


main(@ARGV);

