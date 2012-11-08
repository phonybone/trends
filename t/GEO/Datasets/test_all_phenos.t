#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin";
use lib "$ENV{TRENDS_HOME}/lib";
use GEO;
use Options;			
use PhonyBone::FileUtilities qw(warnf);
use TestAllPhenos;		# derived from PhonyBone::TestCase

our $class='GEO::Dataset';

BEGIN: {
    Options::use(qw(d q v h fuse=i db_name=s));
    Options::useDefaults(fuse => -1, 
			 db_name=>'geo_test',
	);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO->db_name($options{db_name});
    warnf "using %s\n", GEO::Dataset->mongo_coords;
}


sub main {
    my $tc=new TestAllPhenos(class=>$class);
    $tc->test_compiles();
    $tc->test_all_phenos('GDS2381');
    $tc->test_all_phenos('GDS2321');
}

main(@ARGV);

