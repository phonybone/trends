#!/usr/bin/env perl 

#
# Build the series and raw_samples dbs from what exists on disk.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;
use Options;
use PhonyBone::FileUtilities qw(warnf dief dir_files);
use PhonyBone::ListUtilities qw(in_list);

BEGIN: {
  Options::use(qw(d q v h fuse=i filter_gses=s use_datasets db_name=s retain series_file=s));
    Options::useDefaults(fuse => -1, 
			 db_name=>'geo',
			 series_file=>'/proj/price1/vcassen/trends/data/GEO/series.csv',
			 );
    Options::get();
    die Options::usage() if $options{h};
    die "options -q and -d are mutually exclusive\n" if $options{q} && $options{d};
    die "options -q and -v are mutually exclusive\n" if $options{q} && $options{v};
    $ENV{DEBUG} = 1 if $options{d};
    $options{v}=1 if $options{d};
    GEO->db_name($options{db_name});
    $options{retain}=1 if $options{filter_gses};
}

sub main {
    unless ($options{retain}) {
	warnf "removing all records from %s:%s\n", GEO->db_name, GEO::Series->collection;
	warnf "removing all records from %s:%s\n", GEO->db_name, GEO::Series->collection;
	GEO::Series->mongo->remove();
	GEO::RawSample->mongo->remove();
    }
    
    my $filter=GEO::Series->get_filter($options{filter_gses});
    my $line_no=0;
    my $fuse=$options{fuse};
    my $stats;

    open(SERIES, $options{series_file}) or die "Can't open $options{series_file}: $!\n";
    my $header=<SERIES>;	# burn it
    while (<SERIES>) {
	chomp;
	$line_no++;
	my @fields;
	eval {@fields=split_line($_)};
	do { warn $@; $stats->{bad_lines}++; next } if $@;

	unless (@fields==10) {
	    warnf "%s (line %d): wrong number of fields (%d) in %s\n", $fields[0], $line_no, scalar @fields, $_;
	    $stats->{bad_csv_line}++;
	    next;
	}
	my ($GSE, $title, $series_type, $organism, $n_samples, $datasets, $supp_types, $supp_links, $contact, $rel_date)=@fields;
	next unless passes_filter($GSE, $filter);
	next unless lc $organism eq 'homo sapiens';

	# Determine if this entry has already been added, although...
	# why?  The time it takes to enter it isn't going to be much longer than the time it takes to skip it (I think).
	# Test using filter.
	# if the samples in the record match the samples on disk, AND $GSE is already present, you can skip this entry:
	my $series=GEO::Series->new($GSE);

	$series->hash_assign(title=>$title, series_type=>$series_type, organism=>$organism, author=>$contact, date=>$rel_date);
	unless (-r $series->path) {
	    $stats->{no_series_path}++;
	    next;
	}
	my $dir_samples=$series->sample_ids_in_dir;
	$series->sample_ids($dir_samples);
	$series->update({upsert=>1});
	$stats->{new_series}++ unless $series->_id;
	$stats->{n_series}++;

	foreach my $s_id (@{$series->sample_ids}) {
	    my $sample=GEO::RawSample->new($s_id); # sample record might already exist because of multiple series ref-ing sample
	    push @{$sample->series_ids}, $GSE unless in_list($sample->series_ids, $GSE);
	    if (scalar @{$sample->series_ids} > 1) {
		warnf "%s: ignoring extra path in %s\n", $sample->geo_id, $series->geo_id;
	    }
	    $stats->{new_samples}++ unless $sample->_id;
	    $stats->{n_samples}++;
	    $sample->update($sample, {upsert=>1});
	}

	# if we are doing specific GSEs, remove each GSE from the filter as it's processed; quit if we're out of GSEs
	if ($options{filter_gses}) {
	    delete $filter->{$GSE};
	    last unless keys %$filter;
	}

	last if $options{filter_gses} && keys %$filter == 0;
	last if --$fuse==0;
    }
    close SERIES;
    warn "stats\n", Dumper($stats);
}

# return 1 if processing should continue according to filter, undef otherwise.
# delete the element from the filter so that we can end when the filter is empty.
# note that delete returns the item deleted; in this case, if the item was
# present we'd like to continue processing, and if it was absent then we'd
# like to skip to the next element.
sub passes_filter {
    my ($GSE, $filter)=@_;
    return 1 unless $options{filter_gses};
    delete $filter->{$GSE};
}


########################################################################

main(@ARGV);

########################################################################

# fucking GEO left commas in their .csv file
sub split_line {
    my ($line)=@_;
    my @shit=split(/,/, $line);
    my $n_shit=@shit;
 
    my @fields;
    my @curr;
    my $in_quote=0;
    foreach my $s (@shit) {
	if (starter($s)) {
#	    warn "starter: '$s'" if $ENV{DEBUG};
	    dief("two starters: ($s) (%s)", $line) if $in_quote;
	    $in_quote=1;
	    $s=~s/^\"//;		# remove leading quote
	    @curr=($s);

	} elsif (ender($s)) {
	    die "ender outside of quote: $s" unless $in_quote;
#	    warn "ender $s\n" if $ENV{DEBUG};
	    $in_quote=0;
	    $s=~s/\"\s*$//;		# remove trailing quote and any weird ws
	    push @curr, $s;
	    my $field=join(',', @curr);
#	    warn "pushing $field\n" if $ENV{DEBUG};
	    push @fields, $field;
	    @curr=();

	} elsif ($in_quote) {
#	    warn "in_quote: s is $s" if $ENV{DEBUG};
	    $s=~s/\"//g;
	    push @curr, $s;
	    
	} else {
	    $s=~s/^\"(.*)\"\s*$/$1/;
#	    warn "no quote: pushing $s" if $ENV{DEBUG};
	    push @fields, $s;
	}
    }

    wantarray? @fields:\@fields;
}


# routine at the end of the file because it fucks up indenting big time.
my $starter=qr/^".*[^"]$/;
my $ender=qr/^[^"].*"\s*$/;
sub starter { $_[0] =~ /^".*[^"]$/ }
sub ender   { $_[0] =~ /^[^"].*"\s*$/   }
