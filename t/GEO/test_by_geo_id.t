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

use FindBin;
use lib "$FindBin::Bin/../..";

our $class='GEO';
use GEO;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);

    my $r=GEO::by_geo_id('GSE1', 'GSE2');
    is($r,-1);

    my $subref=GEO->can('by_geo_id');
    my @l=qw(GSE1 GDS1);
    my @sl=sort $subref @l;
    is_deeply(\@sl, [qw(GDS1 GSE1)]);

    is_deeply([sort GEO::by_geo_id qw(GDS2 GDS1)], [qw(GDS1 GDS2)], 'same prefix, different num');
    is_deeply([sort GEO::by_geo_id qw(GDS3 GSE3)], [qw(GDS3 GSE3)], 'different prefix, same num');

    is_deeply([sort GEO::by_geo_id qw(GDS3_1 GDS3)], [qw(GDS3 GDS3_1)], 'same gds vs gds_subset');
    is_deeply([sort GEO::by_geo_id qw(GDS3_1 GDS4)], [qw(GDS3_1 GDS4)], 'next gds vs gds_subset');

    is_deeply([sort GEO::by_geo_id qw(GDS3_1 GSE3)], [qw(GDS3_1 GSE3)], 'gse vs gds_subset');
    is_deeply([sort GEO::by_geo_id qw(GSE3 GDS3_1)], [qw(GDS3_1 GSE3)], 'gse vs gds_subset');

    is_deeply([sort GEO::by_geo_id qw(GDS3_11 GDS3_2)], [qw(GDS3_2 GDS3_11)], 'subset vs subset (same gds)');
    is_deeply([sort GEO::by_geo_id qw(GDS4_11 GDS3_2)], [qw(GDS3_2 GDS4_11)], 'subset vs subset (different gds)');
    is_deeply([sort GEO::by_geo_id qw(GDS3_11 GDS4_2)], [qw(GDS3_11 GDS4_2)], 'subset vs subset (different gds)');
    is_deeply([sort GEO::by_geo_id qw(GDS3_2 GDS4_2)], [qw(GDS3_2 GDS4_2)], 'subset vs subset (different gds, same index)');

    # lists with embedded equalities:
    is_deeply([sort GEO::by_geo_id qw(GSE23 GDS54 GSE23)], [qw(GDS54 GSE23 GSE23)]);
    is_deeply([sort GEO::by_geo_id qw(GSM1 GSE23 GDS54 GSE23)], [qw(GDS54 GSE23 GSE23 GSM1)]);
    is_deeply([sort GEO::by_geo_id qw(GSE23 GDS54 GSE23 GDS54_1)], [qw(GDS54 GDS54_1 GSE23 GSE23)]);
    is_deeply([sort GEO::by_geo_id qw(GSE23 GDS54_2 GDS54 GSE23 GDS54_1)], [qw(GDS54 GDS54_1 GDS54_2 GSE23 GSE23)]);
    is_deeply([sort GEO::by_geo_id qw(GDS54_2 GSE23 GDS54_2 GDS54 GSE23 GDS54_1)], [qw(GDS54 GDS54_1 GDS54_2 GDS54_2 GSE23 GSE23)]);
}


main(@ARGV);





