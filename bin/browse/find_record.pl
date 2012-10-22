#!/usr/bin/perl

#
# A script to find one monogoDB record and print it nicely
#
# Usage: find_one.pl <db> <collection> "field=value"
#

use strict;
use warnings;
use MongoDB;
use Data::Dumper;
use Carp;

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;

sub main {
    my $usage="$0 <db> <collection> <field>=<value>";
    my $db=shift or die $usage;
    my $coll=shift or die $usage;

#    @_>=1 or die $usage;
    my $query={};

    foreach my $arg_pair (@_) {
	my ($k,$v)=split(/=/, $arg_pair);
	defined $v or die $usage;
	$query->{$k}=$v;
    }

    my $mongo=get_mongo($db,$coll);
    my $cur=$mongo->find($query, {_id=>0});
    printf "%d records match '%s'\n", $cur->count(), join(', ', map{join(': ', $_, $query->{$_})} keys %$query);

    my @records=map {$_->[1]} sort by_geo_id map {[$_->{geo_id}, $_]} $cur->all;
    

    my $n=0;
    foreach my $record (@records) {
	print "\n*******************\n";
	delete $record->{_id};	# why doesn't {_id=>0} above accomplish this???
	if (my $geo_id=$record->{geo_id}) {
	    my $class=GEO->class_of($geo_id);
	    my $geo=$class->new(%$record);
	    if ($geo->can('report')) {
		printf "%d: %s", ++$n, $geo->report;
		next;
	    }
	}
	print $n++, ": ", Dumper($record);
    }
}

sub by_geo_id($$) { GEO::by_geo_id($_[0]->[0], $_[1]->[0]) }


sub get_mongo {
    my ($db_name, $coll_name)=@_;
    my $connection=MongoDB::Connection->new;
    my $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $collection;
}

sub print_thing {
    my ($thing, $index)=@_;
    $index||=0;
    print ' ' x $index;
    my $r=ref $thing;

    if (! $r) { 
	print "$thing\n";
    } elsif ($r eq 'ARRAY') {
	print_list($thing, $index+1);
    } elsif ($r eq 'HASH') {
	print_hash($thing, $index+1);
    } else {			# just assume it's a hash, even it's an object
	print "$r:\n";
	print_hash($thing, $index+1);
    }
}

sub print_list {
    my $l=shift or confess "no list";
    my $index=shift || 0;
    print "[";
    foreach my $e (@$l) {
	print_thing($e, $index+1);
    }
    print "]\n";
}


sub print_hash {
    my $h=shift or confess "no hash";
    if (ref $h eq 'ARRAY') {
	confess "not a hash: ",Dumper($h);
    }
    my $index=shift || 0;
    foreach my $k (sort keys %$h) {
	my $v=$h->{$k};
	print ' ' x $index;
	printf("%-30s", $k);
	print_thing($v, $index+1);
    }
}

main(@ARGV);
