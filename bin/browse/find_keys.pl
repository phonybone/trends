#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use MongoDB;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my ($mongo_db, $collection_name)=@_;
    die Options::usage(qw(<mongo_db> <collection_name>)) unless $collection_name;
    my $collection=get_mongo($mongo_db, $collection_name);
    my %key2count;
    my %key2types;

    my $cur=$collection->find({}, {_id=>0});
    while ($cur->has_next) {
	my $record=$cur->next;
	foreach my $k (keys %$record) {
	    $key2count{$k}++;
	    my $type=ref $record->{$k} || 'scalar';
	    $key2types{$k}->{$type}++;
	}
    }

    foreach my $k (sort keys %key2count) {
	my $typeshash=$key2types{$k};
	my $types=join(", ", map {"$_: $typeshash->{$_}"} keys %$typeshash);
	printf "%20s\t%d\t%s\n", $k, $key2count{$k}, $types;
    }
}


sub get_mongo {
    my ($db_name, $coll_name)=@_;
    my $connection=MongoDB::Connection->new;
    my $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $collection;
}


main(@ARGV);

