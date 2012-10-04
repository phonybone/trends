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
use File::Spec;
use lib abs_path("$Bin/../../lib");
our $class='TCGA';
use TCGA::Id2Path;

BEGIN: {
    Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    test_path($class);
    test_new($class);
    test_invalid_type($class);
}


sub test_new {
    my ($class)=@_;
    my $type='gbm';
    my $id=23;
    my $tcga=$class->new($type, $id);
    isa_ok($tcga, $class, "got $class($type, $id)");
    isa_ok($class->new(type=>$type, id=>$id), $class);
}

sub test_invalid_type {
    my ($class)=@_;
    eval {$class->new('bad_type', 23)};
    like($@, qr/invalid type/, "caught invalid type");
    # would like to maybe print a more clear error message....
}


sub test_path {
    my ($class)=@_;
    my ($type,$id)=('gbm',23);
    my $tcga=$class->new($type,$id);
    my $path=$tcga->path;
    cmp_ok($path, 'eq', File::Spec->catfile(TCGA::Id2Path->tcga_dir, 
					    $type, 
					    'unc.edu_GBM.AgilentG4502A_07_2.Level_3.1.6.0', 
					    'US45102955_251780410042_S01_GE2-v5_95_Feb07.txt_lmean.out.logratio.gene.tcga_level3.data.txt'));

    ok(-r $path, "readable: $path");
}

main(@ARGV);

