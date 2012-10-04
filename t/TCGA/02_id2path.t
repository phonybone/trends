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
our $class='TCGA::Id2Path';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    test_data_dir($class);
    test_read_manifest($class);
    test_add_type($class);
}


sub test_data_dir {
    my ($class)=@_;
    ok(defined $ENV{TRENDS_HOME}) or BAIL_OUT("\$ENV{TRENDS_HOME} not defined");
    ok(-d $ENV{TRENDS_HOME}) or BAIL_OUT("$ENV{TRENDS_HOME} not a directory");
    ok(-r $ENV{TRENDS_HOME}) or BAIL_OUT("$ENV{TRENDS_HOME} not readable");

    ok(-d $class->tcga_dir, $class->tcga_dir) or BAIL_OUT($class->tcga_dir.": not a directory");
    ok(-r $class->tcga_dir) or BAIL_OUT($class->tcga_dir.": not readable");
}


sub test_read_manifest {
    my ($class)=@_;
    my $id2path=$class->new('gbm');

    cmp_ok($id2path->size, '==', 358);

    cmp_ok($id2path->get(3), 'eq', File::Spec->catfile($id2path->data_dir, 'US45102955_251780410009_S01_GE2-v5_91_0806.txt_lmean.out.logratio.gene.tcga_level3.data.txt'));
    cmp_ok($id2path->get(12), 'eq', File::Spec->catfile($id2path->data_dir, 'US45102955_251780410018_S01_GE2-v5_91_0806.txt_lmean.out.logratio.gene.tcga_level3.data.txt'));
    cmp_ok($id2path->get(357), 'eq', File::Spec->catfile($id2path->data_dir, 'US82800149_251780410635_S01_GE2_105_Dec08.txt_lmean.out.logratio.gene.tcga_level3.data.txt'));
    ok(! defined $id2path->get(358));
}

sub test_add_type {
    my ($class)=@_;
    foreach my $type (qw(gbm brca)) {
	my $subdir=$class->add_type($type);
	ok(-d $subdir, "got subdir for $type");
	ok(-r File::Spec->catfile($subdir, 'MANIFEST.txt'), "got manifest for $type");
    }
}

main(@ARGV);

