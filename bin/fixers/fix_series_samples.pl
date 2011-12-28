#!/usr/bin/env perl 

#
# Use GEO::Series->samples_in_dir() to add filenames to $series->sample_ids
# Ensures all RawSamples records exist for every sample in series.
# Does not address RawSample->dataset, ->subset issues.
# Aside from above, this functionality is now incorporated into parse_series.pl -repair_db
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);
use PhonyBone::ListUtilities qw(all_matching);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::Series;

BEGIN: {
  Options::use(qw(d v h fuse=i query_only|q));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    exit query() if $options{query_only};

    warn "fixing db...\n";
    fix_db();
    warn "generating report...\n";
    query();
}

sub fix_db {
    # for each series in database:
    my @series_recs=GEO::Series->get_mongo_records({});	# tike OLE the records!
    my $fuse=$options{fuse};
    foreach my $r (@series_recs) {
	next unless $r->{geo_id};

	# create a series object by loading from db
	my $series=GEO::Series->new(%$r);

	# replace the {samples} field with list obtained from disk
	unless (series_samples_match($series)) {
	    my $gsm_filenames=$series->samples_in_dir(); 
	    my @gsm_ids=map {/GSM\d+/; $&} @$gsm_filenames;
	    $series->samples(\@gsm_ids);
	    $series->update;
	    warnf ("%s: %s\n", $series->geo_id, join(", ", @{$series->samples})) if $ENV{DEBUG};
	}

	# Ensure that there exists a raw_sample record for each sample, and that it points back to the series
	unless (sample_records_exist($series)) {
	    foreach my $gsm_id ($series->samples) {
		my $rs=GEO->factory($gsm_id);
		$rs->series_id($series->geo_id);
		my $path=(all_matching($series->samples_in_dir(), $gsm_id))[0]; # should be exactly one match
		$rs->path($path);
		warnf ("%s: series_id=%s, path=%s\n", $gsm_id, $series->geo_id, $path) if $ENV{DEBUG};
		$rs->update({upsert=>1});
	    }
	}
	last if --$fuse==0;
    }
}


sub fix_series {
    my $series=(@_);
    my $errors=$series->error_report;
    
    # can't really do anything about records that were in the db but not the filesytem, except maybe report them

    # samples on the fs, but not in the db can be added
    my $all_sample_ids=union($db_samples, $fs_samples);
    $series->samples($all_samples);
    $series->update;

    # missing records comes from 
    my $sample_filenames=$series->samples_in_dir;
    foreach my $sample_id (@{$error->{missing_records}}) {
	my $path=(all_matching($sample_filenames, $sample_id))[0] or do {
	    warnf "%s: missing filename for %s???\n", $series->geo_id, $sample_id;
	    next;
	};
	
	
    }
}

# print a hashref of stats
sub query {
    my @series_recs=GEO::Series->get_mongo_records({});	# tike OLE the records!
    my $fuse=$options{fuse};
    my $stats={total_series=>scalar @series_recs};

    foreach my $r (@series_recs) {
	unless ($r->{geo_id}) {
	    push @{$stats->{no_geo_id}}, $r;
	    next;
	}
	my $series=GEO::Series->new(%$r);
	if (scalar $series->samples_in_dir == 0) {
	    $stats->{n_empty}++;
	    push @{$stats->{empty}}, $series->geo_id;
	}

	if (series_samples_match($series)) {
	    $stats->{n_samples_match}++;
#	    push @{$stats->{samples_match}}, $series->geo_id;
	} else {
	    $stats->{n_samples_mismatch}++;
#	    push @{$stats->{samples_mismatch}}, $series->geo_id;
	    warnf "%s: samples mismatch\n", $series->geo_id;
	}

	if (sample_records_exist($series)) {
	    $stats->{n_sample_records_exist}++;
#	    push @{$stats->{all_sample_records_exist}}, $series->geo_id;
	} else {
	    $stats->{n_sample_records_no_exist}++;
#	    push @{$stats->{missing_sample_records}}, $series->geo_id;
	    warnf "%s: samples records missing\n", $series->geo_id;
	}
    }
    print Dumper($stats);
}


# for a given series, does the record match what's on disk?
sub series_samples_match {
    my ($series)=@_;
    my $db_samples=[sort @{$series->samples}];
    my $fs_samples=[sort grep {/GSM\d+/; $&} $series->samples_in_dir]; # extract GSM ids out of filenames
    return undef if scalar @$db_samples != scalar @$fs_samples;

    for (my $i=0; $i<scalar @$db_samples; $i++) {
	return undef unless $db_samples->[$i] eq $fs_samples->[$i];
    }    
    1;
}

sub sample_records_exist {
    my ($series)=@_;
    foreach my $rs_id (@{$series->samples}) {
	defined GEO->factory($rs_id)->_id or return undef;
    }
    1;
}

main(@ARGV);

