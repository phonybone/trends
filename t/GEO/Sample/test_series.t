#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use PhonyBone::ListUtilities qw(in_list);

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use GEO;

our $class='GEO::Sample';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $gsm=GEO::Sample->new('GSM29804');
#    warn "test_series: gsm is ",Dumper($gsm);
    isa_ok($gsm, 'GEO::Sample');
    is($gsm->geo_id, 'GSM29804', 'got gsm->geo_id');
    ok(in_list($gsm->dataset_ids, 'GDS968'), 'got gsm->dataset_ids');
    my $ds=GEO->factory('GDS968');
    is ($ds->pubmed_id, 15096622);
    
    my $series=$gsm->series->[0];
#    warn "test_series: series is ", Dumper($series);
    isa_ok($series, 'GEO::Series');
    is ($series->geo_id, 'GSE1977');
}

main(@ARGV);
