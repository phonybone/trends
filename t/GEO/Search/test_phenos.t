#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf);

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../../../lib");
use lib $Bin;
use TestSearch;
our $class='GEO::Search';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $dataset_mongo=GEO::Dataset->mongo;
    cmp_ok($dataset_mongo->full_name, 'eq', 'geo_test.datasets', $dataset_mongo->full_name);
    

    my $tc=TestSearch->new(class=>$class);

    $tc->test_search_mongo('asthma', 'GEO::Sample', 'phenotypes', 70);
    $tc->test_add_results();
    exit;
    $tc->test_consolidate('cancer');

    $tc->test_consolidate('glioblastoma');
    $tc->test_expand('glioblastoma');

    $tc->test_results('glioblastoma');
}

main(@ARGV);

