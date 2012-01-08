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
    
    # same series test
    my $geo_id='GSM531989';
    my $raw_sample=GEO::RawSample->new(geo_id=>$geo_id);

    my $next_sample=$raw_sample->next;
    is ($next_sample->geo_id, 'GSM531990');

    # cross series test:
    my $geo_id='GSM531992';
    my $raw_sample=GEO::RawSample->new(geo_id=>$geo_id);

    my $next_sample=$raw_sample->next;
    is ($next_sample->geo_id, 'GSM531993');

    
}

main(@ARGV);
