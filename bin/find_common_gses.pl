#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;

# Prints a list of GSE's common to both datasets and series (?)
 
use Options;
use PhonyBone::FileUtilities qw(file_lines warnf dief);
use PhonyBone::ListUtilities qw(intersection);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $fn1='/proj/price1/vcassen/trends/data/GEO/series.gses.hs';
    my $fn2='/proj/price1/vcassen/trends/data/GEO/datasets/gses';

    my @l1=map {/GSE\d+/; $&} file_lines($fn1);
    my @l2=map {/GSE\d+/; $&} file_lines($fn2);

    my @common=intersection(\@l1, \@l2);
    do {print "$_\n"} for @common;
    
}

main(@ARGV);

