#!/usr/bin/env perl 
#-*-perl-*-

# Test the functionality of the path() method


use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use GEO;

our $class='GEO::Sample';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $gsm=GEO::Sample->new('GSM92819');
    warn $gsm->json;
}

main(@ARGV);
