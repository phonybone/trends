#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../..";
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
    warn "test_series: gsm is ",Dumper($gsm);
    isa_ok($gsm, 'GEO::Sample');
    is($gsm->geo_id, 'GSM29804', 'got gsm->geo_id');
    is($gsm->dataset_id, 'GDS968', 'got gsm->dataset_id');

    my $series=$gsm->series;
    warn "test_series: series is ", Dumper($series);
    isa_ok($series, 'GEO::Series');
    is ($series->geo_id, 'GDS968');
    is ($series->title, 'DNA damage from ultraviolet and ionizing radiation effect on peripheral blood lymphocytes');
    is ($series->pubmed_id, 15356296);

    exit 1;
    
    my $series2=GEO->factory($gsm->dataset_id);
    warn "series2 is ",Dumper($series2);

    is_deeply($series, $series2, "series are deeply the same");
}

main(@ARGV);
