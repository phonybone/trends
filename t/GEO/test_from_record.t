#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../../lib");
use lib abs_path("$Bin");

use Options;			
use TestFromRecord;		# derived from PhonyBone::TestCase
use GEO::Sample;

our $class='GEO';

BEGIN: {
    Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO::Sample->db_name('geo_test');
}


sub main {
    my $tc=new TestFromRecord(class=>$class);
    $tc->run_all_tests();
}

main(@ARGV);

