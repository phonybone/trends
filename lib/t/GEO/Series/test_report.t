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


our $class='GEO::Series';
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
    my $gse='GSE14777';
    my $series=$class->new($gse);
    warn $series->report, "\n";

    $gse='GSE2980';
    $series=$class->new($gse);
    warn $series->report, "\n";
    
}

main(@ARGV);
