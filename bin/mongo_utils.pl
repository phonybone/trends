#!/usr/bin/env perl 

# Utility routines for MongoDB dbs

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;

our ($connection, $db, %mongos);

sub get_mongo {
    my ($db_name, $coll_name)=@_;
    return $mongos{$coll_name} if $mongos{$coll_name};

    $connection=MongoDB::Connection->new;
    $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $mongos{$coll_name}=$collection;
    $collection;
}

1;
