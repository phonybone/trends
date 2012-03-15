#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../lib";

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
    
    my $geo_id='GSE10072';
    my $geo=GEO->factory($geo_id);
    my $base='localhost';
    my $uri=$geo->uri($base);
    is($uri, "http://$base/geo/$geo_id");

    $uri=$geo->uri($base, 'json');
    is($uri, "http://$base/geo/$geo_id.json");
}

main(@ARGV);

