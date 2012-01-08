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

our $class='GEO';
use GEO::RawSample;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    
    my $geo_id='GSM531989';
    my $raw_sample=GEO::RawSample->new(geo_id=>$geo_id);
    isa_ok($raw_sample, 'GEO::RawSample');

    my @series=$raw_sample->series_list;
    is (scalar @series, 2, "got 2 series");
    is ($series[0]->geo_id, 'GSE21280', 'got GSE21280');
    is ($series[1]->geo_id, 'GSE21284', 'got GSE21284');
}

main(@ARGV);
