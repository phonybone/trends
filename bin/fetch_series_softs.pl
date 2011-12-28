#!/usr/bin/env perl 

#
# Fetch the .soft file for all series that have been downloaded
# Doesn't write to any dbs.
# Uses GEO::Series->fetch_soft
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;

use Options;
use PhonyBone::FileUtilities qw(warnf file_lines);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;

BEGIN: {
  Options::use(qw(d q v h fuse=i gses=s));
    Options::useDefaults(fuse => -1, gses=>[]);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    my $gses=get_gses();
    warnf "fetching %d series soft files...\n", scalar @$gses;

    my $fuse=$options{fuse};
    my $stats={fuse=>$fuse};

    foreach my $gse (@$gses) {
	my $series=new GEO::Series($gse);
	mkdir $series->path unless -d $series->path;

	if (-r $series->softpath) {
	    $stats->{previous}++;
	    warnf("%s: softpath already exists\n", $series->geo_id);
	    next;
	}
	
	eval {
	    $series->fetch_soft;
	    if (-r $series->softpath) {
		$stats->{downloaded}++;
		warnf("%s downloaded\n", $series->softpath) unless $options{q};
	    }
	}; if ($@) {
	    warnf "Unable to download softpath for %s: %s\n", $series->geo_id, $@;
	    $stats->{errors}++;
	}
	
	last if --$fuse==0;
    }
    warn "stats: ",Dumper($stats);
}

sub get_gses {
    my @gses;
    if (my $gse_list=$options{gses}) { # can either be command-line list or name of file containing "\n"-separated list
	if (-r $gse_list->[0]) {
	    @gses=map {chomp; $_} file_lines($gse_list->[0]);
	} elsif (ref $gse_list eq 'ARRAY') {
	    @gses=@$gse_list;
	} else {
	    die "Don't know how to convert to list of gse's: ", Dumper($gse_list);
	}
    } else {			# get all gses from db:
	@gses=map {$_->{geo_id}} GEO::Series->get_mongo_records;
    }
    wantarray? @gses:\@gses;
}




main(@ARGV);
