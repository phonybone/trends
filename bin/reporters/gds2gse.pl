#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
# This script looks through all the datasets and reports whether or not the corresponding 
# series has been downloaded.

use Options;
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use GEO;

BEGIN: {
  Options::use(qw(d q v h fuse=i fix_status));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my @gds_recs=GEO::Dataset->get_mongo_records();
    #print "gds->gse:\tdb\tstatus\t-d path\n";
    printf "%18s: %s\t%s\t%s\t%s\t%s\t%s\n", 'gds->gse', '-e rec', 'status', '-d path', 'n_gds_sam', 'n_ser_samp', 'n_samps =';
    print "---------------------------------------------------------------------------------------------\n";

    my $fuse=$options{fuse};
    foreach my $rec (@gds_recs) {
	warn "rec is ",Dumper($rec) if $ENV{DEBUG};
	my $gds=$rec->{geo_id};
	my $gse=$rec->{reference_series};
	my $series=new GEO::Series($gse);
	warn "series is ", Dumper($series) if $ENV{DEBUG};

	my $rec_exists=$series->_id? 'yes':'no';
	my $status=$series->status || '<unknown>';
	my $d_exists=-d $series->path? 'yes':'no';
	my $n_gds_samples=$rec->{sample_count};
	my $n_rec_samples=eval {scalar @{$series->sample_ids}} || -1;
#	my $n_dir_samples=scalar @{$series->sample_ids_in_dir};
	my $n_samples_match=$n_gds_samples==$n_rec_samples? 'yes':'no';

	my $fix='';
	if ($options{fix_status} && $status eq '<unknown>') {
	    if ($rec_exists eq 'yes' && $d_exists eq 'yes' && $n_rec_samples > 0) {
		$fix='+';
		$series->status('downloaded');
	    } else {
		$series->status('pending download');
		warnf "needs download: %gse\n";
	    }
	    $series->update;
	}

	printf "%8s->%8s: %3s\t%12s\t%3s\t%9d\t%9d\t%3s\t%s\n", $gds, $gse, $rec_exists, $status, $d_exists, $n_gds_samples, $n_rec_samples, $n_samples_match, $fix;

	last if --$fuse==0;
    }
}

main(@ARGV);

