#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../../..";

our $class='GEO::RawSample::Iterator';
use GEO::Series;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $series_id='GSE32507';
    my $series=GEO->factory($series_id);
    my $dir=$series->path;
    my $it=$class->new(dir=>$dir);
    my $n_samples=0;
    while (my $n=$it->next) { $n_samples++ }
    my $expected=46;
    is ($n_samples, $expected, "got $expected samples from $series_id");
}

main(@ARGV);
