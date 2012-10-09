#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf);
use PhonyBone::TimeUtilities qw(tlm);
use Test::More qw(no_plan);

use FindBin qw($Bin);
use lib "$Bin/../../lib";
use lib "$Bin";

our $class='GEO';
use GEO::word2geo;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    $class->testing(1);		# changes dbs to 'geo_test' (hopefully)
    warn "\n*******************\nThis test needs a fixture db\n*******************\n";

    GEO::word2geo->mongo->remove; # wipe clean
    GEO::word2geo->mongo->drop_indexes();
    my @indexes=GEO::word2geo->mongo->get_indexes;
    is (scalar @indexes, 1, "wiped indexes (except of _id)");
    warn Dumper(\@indexes) if @indexes > 1;

    my $cancer2938=GEO::word2geo->new(geo_id=>'GSE2938', word=>'cancer')->insert;
    delete $cancer2938->{_id}; $cancer2938->insert;
    delete $cancer2938->{_id}; $cancer2938->insert;

    my $tumor2939=GEO::word2geo->new(geo_id=>'GSE2939', word=>'tumor')->insert;
    GEO::word2geo->new(geo_id=>'GSE2939', word=>'tumor')->insert;
    delete $tumor2939->{_id}; $tumor2939->insert;

    GEO::word2geo->new(geo_id=>'GSE2940', word=>'cyst')->insert;

    my @records=GEO::word2geo->mongo->find->all;
    is (scalar @records, 6, "got 6 starting records");

    my $w2g=GEO::word2geo->new(geo_id=>'GSE2938', word=>'cancer');
    $w2g->remove_dups;

    @records=GEO::word2geo->mongo->find->all;
    is (scalar @records, 4, "got 4 remainig records (total)");

    @records=GEO::word2geo->mongo->find->all($w2g);
    is (scalar @records, 1, "got 1 remainig record for (GSE2938, cancer))");
    
    
}

main(@ARGV);

