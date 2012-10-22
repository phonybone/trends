#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../../lib";

our $class='GEO';
use GEO::Series;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    
    my $geo_id='GSE14777';
    my $series=GEO::Series->new(geo_id=>$geo_id);
    my $record=$series->get_mongo_record;
    warn Dumper($record);

#    my $expected_platform='GPLxxx';
#    is($series->platform->get_id, 'GPLxxx', "got '$expected_platform' for series $geo_id");
}

main(@ARGV);
