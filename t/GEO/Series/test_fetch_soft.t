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
    isa_ok ($series, $class, "instanciated GEO::Series->$geo_id");
    
    unlink $series->soft_path;
    $series->fetch_soft;
    ok (-r $series->soft_path, (sprintf "downloaded %s", $series->soft_path));
}

main(@ARGV);
