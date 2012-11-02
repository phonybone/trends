#!/usr/bin/env perl 

# go in to db.series and change all $r->{sample_id} to $r->{sample_ids}

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;			# PhonyBone::Options, sorta
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib abs_path("$ENV{TRENDS_HOME}/lib");
use GEO;

BEGIN: {
    Options::use(qw(d q v h fuse=i db_name=s));
    Options::useDefaults(fuse => -1, 
			 db_name=>'geo',
	);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO::Series->db_name($options{db_name});
    warnf "writing to %s\n", GEO::Series->mongo_coords;
}


sub main {
    my $stats={};
    my $fuse=$options{fuse};
    $stats->{fuse}=$fuse unless $fuse<0;

    my $cursor=GEO::Series->mongo->find({sample_id => qr/./});
    warnf "changing %d series records\n", $cursor->count;
    $stats->{total_series}=$cursor->count;

    while ($cursor->has_next) {
	my $series=$cursor->next;
	$series->{sample_ids}=delete $series->{sample_id};
	GEO::Series->mongo->save($series);
	$stats->{n_changed}++;
	last if --$fuse==0;
    }
    warn Dumper($stats);
}

main(@ARGV);

