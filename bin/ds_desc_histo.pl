#!/usr/bin/env perl 

#
# Create a histogram of words based on the descriptions found in the datasets db (including subsets)
# Maybe useful for ds->pheno.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::Dataset;
use GEO::DatasetSubset;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $word2freq={};
    my $word2geo=get_mongo('geo', 'word2geo');
    $word2geo->ensure_index({word=>1, geo_id=>1}, {unique=>1});
    
    my $records=GEO::Dataset->get_mongo_records(); 
    warnf "%d dataset records\n", scalar @$records;
#    insert($records, $word2geo);
    count($records, $word2freq);

    $records=GEO::DatasetSubset->get_mongo_records(); 
    warnf "%d subset records\n", scalar @$records;
    count($records, $word2freq);
#    insert($records, $word2geo);

    # sort by freq:
    my @words=map {$_->[0]} sort {$a->[1] <=> $b->[1]} map {[$_, $word2freq->{$_}]} keys %$word2freq;
    foreach my $word (@words) {
	my $freq=$word2freq->{$word};
	printf "%30s\t%d\n", $word, $freq;
    }
    exit;

    # sort by words:
    foreach my $word (sort keys %$word2freq) {
	my $freq=$word2freq->{$word};
	printf "%30s\t%d\n", $word, $freq;
    }
}

# add record contents to the histogram
sub count {
    my ($records, $histo, $word2geo)=@_;
    foreach my $r (@$records) {
	foreach my $field (qw(title description author)) {
	    foreach my $word (split(/\s+/, $r->{$field})) {
		$word=normalize($word) or next;	# skip blanks
		next if $word=~/^\d+$/;	# skip numbers
		$histo->{$word}++;

		eval {
		    $word2geo->insert({word=>$word, geo_id=>$record->{geo_id}});
		};
	    }
	}
    }
}

# currently just removes non-\w and non-\d chars, and lower-cases everything
sub normalize {
    my $word=shift;
    $word=lc $word;
    $word=~s/[^\w\d_]//g;
    $word;
}

sub get_mongo {
    my ($db_name, $coll_name)=@_;
    $connection=MongoDB::Connection->new;
    $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $collection;
}


main(@ARGV);

