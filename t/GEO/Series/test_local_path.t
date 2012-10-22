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

    my $data_dir=GEO->data_dir;
    is ($series->path, join('/',$data_dir, 'series', $series->geo_id), "got path for $geo_id");
    ok (-d $series->path, "path for $geo_id exists and is a directory");
    
}

main(@ARGV);
