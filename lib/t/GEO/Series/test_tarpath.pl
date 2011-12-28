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
    isa_ok ($series, $class, "instanciated $class");
    
    my $tarpath=$series->tarpath;
    my $GSE=$series->geo_id;
    is ($tarpath, join('/', GEO->data_dir, 'series', $GSE, "${GSE}_RAW.tar"), "got $tarpath");
}

main(@ARGV);
