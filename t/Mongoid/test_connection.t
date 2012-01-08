#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

# Test the ability to connect to a db,
# including inheritence cases.


use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../..";
our $class='Mongoid';
use Person;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $person_mongo=Person->mongo;
    isa_ok($person_mongo, 'MongoDB::Collection');
    is ($person_mongo->{name}, 'people', 'name of Person->mongo is "people"');

    is_deeply (Mongoid->mongo_dbs->{Person}, $person_mongo, "cached db is (deeply) the same");
}

main(@ARGV);

