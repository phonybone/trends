#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../..";

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
    my $series=GEO::Series->new(geo_id=>$geo_id)->get_mongo_record;
    is(ref $series->record, 'HASH', "got the hash for $geo_id");
    is($series->record->{geo_id}, $geo_id, "got $geo_id in record");
    warn Dumper($series);
}

main(@ARGV);

