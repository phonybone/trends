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

our $class='GEO::SeriesData';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);

    my $gsd=GEO::SeriesData->new('GSM29804');
    warn "test_series: gsd is ",Dumper($gsd);
    is ($gsd->path, join('/', $self->data_dir, 'GSM298', 'GSM29804.data'));

    my $gsd=GEO::SeriesData->new('GSM736431');
    warn "test_series: gsd is ",Dumper($gsd);
    is ($gsd->path, join('/', $self->data_dir, 'GSM298', 'GSM29804.data'));

    my $gsd=GEO::SeriesData->new('GSM29804');
    warn "test_series: gsd is ",Dumper($gsd);
    is ($gsd->path, join('/', $self->data_dir, 'GSM298', 'GSM29804.data'));

    my $gsd=GEO::SeriesData->new('GSM29804');
    warn "test_series: gsd is ",Dumper($gsd);
    is ($gsd->path, join('/', $self->data_dir, 'GSM298', 'GSM29804.data'));

}

main(@ARGV);
