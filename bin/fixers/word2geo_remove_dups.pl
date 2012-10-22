#!/usr/bin/env perl 

#
# Create a histogram of words based on the descriptions found in the datasets db (including subsets)
# Maybe useful for ds->pheno.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;

use Options;
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::word2geo;

BEGIN: {
  Options::use(qw(d q v h fuse=i fix=i db_name=s));
    Options::useDefaults(fuse => -1, fix=>1, db_name=>'geo');
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    my $word2geo=get_mongo($options{db_name}, 'word2geo');
    
    # assemble query using "k=v" pairs:
    my $query={};
    foreach (@_) {
	if (/(\w+)=(\w+)/) {
	    my ($k,$v)=($1,$2);
	    $query->{$k}=$v;
	}
    }
    my @records=$word2geo->find($query)->sort({geo_id=>1, word=>1})->all;
    printf "got %d records\n", scalar @records;
    map {delete $_->{_id}} @records;

    my $fuse=$options{fuse};
    my $first_r=shift @records;
    my $prev=new GEO::word2geo(%$first_r);
    my $n_dups=0;
    my $total_dups=0;

    foreach my $r (@records) {
	my $curr=new GEO::word2geo($r);
	if ($curr->equals($prev)) {
	    $n_dups++;
	    $total_dups++;
	} else {		# $curr ne $prev_s
	    if ($n_dups==0) {
		printf "%s is unique\n", $prev->as_string;
	    } else {
		my $s=$n_dups==1? '':'s';
		printf "%s: $n_dups dup$s\n", $prev->as_string;
		$prev->remove_dups({safe=>1}) if $options{fix};
	    }
	    $prev=$curr;
	    $n_dups=0;		# reset counter
	}
	last if --$fuse==0;
    }

    # tail case:
    $prev->remove_dups({safe=>1}) if $n_dups > 0 && $options{fix};

    print "$total_dups total dups\n";
}

our ($connection, $db);
sub get_mongo {
    my ($db_name, $coll_name)=@_;
    $connection=MongoDB::Connection->new;
    $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $collection;
}


main(@ARGV);
