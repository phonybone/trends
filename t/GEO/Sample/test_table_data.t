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

    is_deeply ($series->phenotypes, ['asthma'], "$geo_id: pheno is ".join(', ',@{$series->phenotypes}));
    
    ok (-e $series->table_data_file, $series->table_data_file." exists");
    ok (-r $series->table_data_file, $series->table_data_file." readable");

    
    
}

main(@ARGV);
