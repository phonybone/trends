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

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
#    test_raw_sample();
#    test_dataset();
#    test_sample();
    test_series();
}

sub test_raw_sample {
    my $rs_id='GSM815436';
    my $rs=GEO->next($rs_id);
    isa_ok($rs, 'GEO::RawSample');
    is($rs->geo_id, 'GSM815437');
    is($rs->series_id, 'GSE32924');
}

sub test_dataset {
    my $ds_id='GDS1020';
    my $ds=GEO->next($ds_id);
    warnf "ds is %s", Dumper($ds);
    is ($ds->geo_id, 'GDS1022');
    is ($ds->reference_series, 'GSE1469');
}

sub test_series {
    my $series_id='GSE12806';
    my $series=GEO->factory($series_id);
    isa_ok($series, 'GEO::Series');
    is_deeply ($series->samples, [ "GSM321605", "GSM321608", "GSM321606", "GSM321607" ]);

    my $next_sample=GEO->next('GSM321606');
    is($next_sample->geo_id, 'GSM321607');
    is($next_sample
}

main(@ARGV);

