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

our $class='GEO::SeriesData';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $gsd=GEO::SeriesData->new('GSM29804');
    warn "test_series: gsd is ",Dumper($gsd);
    isa_ok($gsd, 'GEO::SeriesData');
    is($gsd->geo_id, 'GSM29804', 'got gsd->geo_id');
    is($gsd->dataset_id, 'GDS913', 'got gsd->dataset_id');

    my $series=$gsd->series;
    warn "test_series: series is ", Dumper($series);
    isa_ok($series, 'GEO::Series');
    is ($series->geo_id, 'GDS913');
    is ($series->title, 'DNA damage from ultraviolet and ionizing radiation effect on peripheral blood lymphocytes');
    is ($series->pubmed_id, 15356296);

    exit 1;
    
    my $series2=GEO->factory($gsd->dataset_id);
    warn "series2 is ",Dumper($series2);

    is_deeply($series, $series2, "series are deeply the same");
}

main(@ARGV);
