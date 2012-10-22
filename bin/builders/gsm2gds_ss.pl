#!/usr/bin/perl

#
# Map raw_samples back to their dataset and database_subset.
#

use strict;
use warnings;
use Carp;

use MongoDB;
use Term::ReadLine;

use Options;
use PhonyBone::FileUtilities qw(warnf dief);
require 'mongo_utils.pl';

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;

BEGIN: {
    Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1, 
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    my $subsets=get_mongo('geo', 'dataset_subsets');
    my $gds_n2gsm2=get_mongo('geo', 'gds_n2gsm2');
    $gds_n2gsm2->ensure_index({gds_n=>1});
    $gds_n2gsm2->ensure_index({gsm=>1});
    $gds_n2gsm2->ensure_index({gds_n=>1, gsm=>1}, {unique=>1});

    my $gds2gsm2=get_mongo('geo', 'gds2gsm2');
    $gds2gsm2->ensure_index({gds=>1});
    $gds2gsm2->ensure_index({gsm=>1});
    $gds2gsm2->ensure_index({gds=>1, gsm=>1}, {unique=>1});
    

    my @records=$subsets->find->all;
    warnf("got %d records\n", scalar @records);
    my $fuse=$options{fuse};
    foreach my $record (@records) {
	$record->{geo_id}=~/^GDS\d+/ or dief "wtf??? geo_id=%s", $record->{geo_id};
	my $gds=$&;

	my $sample_ids=$record->{sample_id};
	my @sample_ids=split(/[,\s]+/,$sample_ids);
	warnf("got %d samples for %s\n", scalar @sample_ids, $record->{geo_id}) if $ENV{DEBUG};
	foreach my $sample_id (@sample_ids) {
	    $gds_n2gsm2->insert({gds_n=>$record->{geo_id}, gsm=>$sample_id});
	    $gds2gsm2->insert({gds=>$gds, gsm=>$sample_id});
	    warnf("%s -> %s\n", $record->{geo_id}, $sample_id) if $ENV{DEBUG};
	}

	last if --$fuse==0;
    }


}

main(@ARGV);
