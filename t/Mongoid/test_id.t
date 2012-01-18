#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf dief);
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use GEO;
use GEO::Series;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    GEO->db_name('geo_test');
    my $geo_id='GSE10072';
    test_insert($geo_id);
    test_update($geo_id);
    test_upsert($geo_id);
}

sub test_insert {
    my ($geo_id)=@_;
    GEO::Series->mongo->remove({geo_id=>$geo_id});

    my $series=new GEO::Series($geo_id);
    warnf "%s: _id=%s\n", $geo_id, ($series->_id || '<none>');
    my $self=$series->insert({safe=>1});
    isa_ok($series->_id, 'MongoDB::OID');
}

sub test_update {
    my ($geo_id)=@_;
    GEO::Series->mongo->remove({geo_id=>$geo_id});
    my $series=new GEO::Series($geo_id);
    is ($series->_id, undef, "got _id=undef after update of new object");
    $series->author('Fred');
    $series->update;
    is ($series->_id, undef, "got _id=undef after update of new object");
}

sub test_upsert {
    my ($geo_id)=@_;
    my $series=new GEO::Series($geo_id);
    $series->author('Fred');
    $series->update({upsert=>1});
    isa_ok ($series->_id, 'MongoDB::OID', "got _id=MongoDB::OID after upsert of new object");
}

main(@ARGV);

