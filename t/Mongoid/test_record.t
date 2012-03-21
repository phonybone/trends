#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin;
use Cwd 'abs_path';
use lib abs_path("$FindBin::Bin/../../lib");
our $class='Mongoid';
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
    my $series=GEO->factory('GSE10072');
    isa_ok($series, 'GEO::Series') or die "unable to get series object";
    my $record=$series->record;
    is(ref $record, 'HASH', 'got a hash');
    
}

main(@ARGV);

