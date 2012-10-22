#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../../lib";

our $class='GEO::Dataset';
use GEO::DatasetSubset;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    
    my $geo_id='GDS3705';
    my $ds=GEO::Dataset->new(geo_id=>$geo_id);
    isa_ok($ds, $class, "instanciated $class");
    
    test_subsets($ds);
    test_samples($ds);
}

sub test_subsets {
    my ($ds)=@_;
    my $geo_id=$ds->geo_id;
    is ($ds->sample_count, 15, "got 15 samples");

    my $subsets=$ds->subsets;
    is (scalar @$subsets, 2, "got 2 subsets");

    is ($subsets->[0]->geo_id, join('_',$geo_id,'1'));
    is ($subsets->[0]->dataset_id, $geo_id);
    is (scalar @{$subsets->[0]->sample_ids}, 8, 'got 8 samples');

    is ($subsets->[1]->geo_id, join('_',$geo_id,'2'));
    is ($subsets->[1]->dataset_id, $geo_id);
    is (scalar @{$subsets->[1]->sample_ids}, 7, 'got 7 samples');
}

sub test_samples {		# aka SeriesData
    my ($ds)=@_;
    my $subsets=$ds->subsets;
    
    foreach my $ss (@$subsets) {
	my $samples=$ss->samples;
	foreach my $s (@$samples) {
	    foreach my $ds_id (@{$s->dataset_ids}) {
		is ($ds_id, $ds->geo_id);
	    }
	}
    }
}

main(@ARGV);
