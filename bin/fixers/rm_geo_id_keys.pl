#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use lib "$ENV{TRENDS_HOME}/lib";
use GEO::Series;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $stats={};
    while (my $gse=<DATA>) {
	chomp $gse;
	warn "$gse\n" unless $options{q};
	my $geo_id=(split('_', $gse, 2))[1];
	my $geo=GEO->factory($geo_id);
	delete $geo->{$gse};
	$geo->update;
	$stats->{n_updated}++;
    }
    warn Dumper($stats);
}

main(@ARGV);

__DATA__
subset_GDS1012_1
subset_GDS1012_2
subset_GDS1012_3
subset_GDS1012_4
subset_GDS1012_5
