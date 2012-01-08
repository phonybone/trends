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
    my $geo_id='GSM177212';	# this is one of Shuyi's
    my $series=$class->new($geo_id);
#    warn Dumper($series);
    is ($series->phenotype, 'asthma', "$geo_id: pheno is ".$series->phenotype);
    
    ok (-e $series->datafile, $series->datafile." exists");
    ok (-r $series->datafile, $series->datafile." readable");

    
    
}

main(@ARGV);
