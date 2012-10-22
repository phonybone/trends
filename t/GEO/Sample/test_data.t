#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use PhonyBone::ListUtilities qw(in_list);

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
    my $sample=$class->new($geo_id);
    warn Dumper($sample->phenotypes);
    ok (in_list($sample->phenotypes, 'asthma'), "$geo_id: pheno is ".join(', ',@{$sample->phenotypes}));
    
    ok (-e $sample->table_data_file, $sample->table_data_file." exists");
    ok (-r $sample->table_data_file, $sample->table_data_file." readable");

    
    
}

main(@ARGV);
