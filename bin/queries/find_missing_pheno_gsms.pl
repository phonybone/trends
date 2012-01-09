#!/usr/bin/env perl 

#
# Find all gsms records that have a phenotype defined, but are missing data on disk:
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use FindBin;
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use lib "$FindBin::Bin/../../lib";
use GEO;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $stats={
	n_missing_data_file=>0,
	n_missing_table_data_file=>0,
	n_missing_gses=>0,
    };
    my @gsm_recs=GEO::Sample->get_mongo_records({phenotype => {'$ne'=>undef}});
    warnf "found %d gsm recs w/phenotype\n", scalar @gsm_recs;
    $stats->{n_pheno_gsms}=scalar @gsm_recs;
    my $missing_gses={};

    my %soft_paths;
    foreach my $rec (@gsm_recs) {
	my $sample=GEO::Sample->new($rec->{geo_id});
	-r $sample->data_file or $stats->{n_missing_data_file}++;
	-r $sample->table_data_file or $stats->{n_missing_table_data_file}++;

	foreach my $gse (@{$sample->series_ids}) {
	    my $series=GEO::Series->new($gse);
	    if (! -r $series->soft_path) {
		push @{$missing_gses->{$gse}}, $sample->geo_id;
		$soft_paths{$gse}=$series->soft_path;
	    }
	}
    }
    $stats->{n_missing_gses}=scalar keys %$missing_gses;
    foreach my $gse (sort keys %$missing_gses) {
	warnf "%9s: %3d missing gsms (%s)\n", $gse, scalar @{$missing_gses->{$gse}}, $soft_paths{$gse};
    }
    warn Dumper($stats);
}

main(@ARGV);

