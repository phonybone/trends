#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf dief);
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../../lib";

our $class='GEO';
use GEO::Series;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    
    my $geo_id='GSE14777';
    my $series=GEO::Series->new(geo_id=>$geo_id);
    warn "series is ", $series->report;

    test_samples($series);
    test_sample_ids($series);
    test_phenos(GEO->factory('GSE1650'));
    
}

sub test_sample_ids {
    my ($series)=@_;

    # check for presence of all samples, both ways:
    my @samples=sort qw(GSM368874  GSM368875  GSM368876  GSM368891  GSM368893);
    warn Dumper($series->sample_ids);
    foreach my $s (@samples) {
	ok((grep /^$s$/, @{$series->sample_ids}), "got expected sample $s");
    }

    foreach my $s (@{$series->sample_ids}) {
	ok((grep /^$s$/, @samples), "got series sample $s");
    }

    my $disk_samples=[sort $series->sample_ids_in_dir];
    is_deeply(\@samples, $disk_samples, "database matches disk");

}

sub test_samples {
    my ($series)=@_;
    foreach my $sample (@{$series->samples}) {
#	warn "sample is ", Dumper($sample);
#	warnf "sample %s (%s)", $sample->geo_id, ref $sample;
	isa_ok($sample, 'GEO::Sample', sprintf("%s is a %s", $sample->geo_id, ref $sample));
    }
}

sub test_phenos {
    my ($series)=@_;
    my $phenos=$series->phenotypes;

    my $samples=$series->samples;
    warnf "%s has %d samples\n", $series->geo_id, $series->n_samples;

    foreach my $sample (@$samples) {
	foreach my $pheno (@{$sample->phenotypes}) {
	    ok ($series->has_pheno($pheno), $pheno);
	}
    }
}

main(@ARGV);

