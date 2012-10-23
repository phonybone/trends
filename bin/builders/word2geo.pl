#!/usr/bin/env perl 

#
# For a given geo collection (or class), use fields specified by class->word_fields
# to connect all relevent words to this geo_id.  Store in the word2geo collection.
# 
# Usage: perl word2geo.pl <class> [-opts]
# 
# 17Oct2001: Coding style is outdated, but this script is still functional.
# But it seems to overlap with parse_series_soft.pl? No, that code is commented out.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;

use Options;
use PhonyBone::FileUtilities qw(warnf);

use lib "$ENV{TRENDS_HOME}/lib";
use GEO;
use GEO::word2geo;


BEGIN: {
    Options::use(qw(d q v h fuse=i db_name=s phrase));
    Options::useDefaults(fuse => -1, db_name=>'geo');
    Options::get();
    die Options::usage(qw([class])) if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    $options{v}=1 if $options{d};
    GEO->db_name($options{db_name});
    GEO::word2geo->db_name($options{db_name});
    warnf "writing to %s\n", GEO::word2geo->mongo_coords;
}

sub main {
    my $class=shift or die usage(qw([class]));
    $class='GEO::'.$class unless $class=~/^GEO::/;
    my $stats={};

    my $word2geo=GEO::word2geo->mongo;
    my $src_mongo=$class->mongo;
    my $word_fields=$class->word_fields;
    warn "$class: word_fields=",join(', ', @$word_fields), "\n" if $options{v};
    # build the fields hash used in the mongo query:
    my %fields=map {($_, $_)} @$word_fields;

    # get all the records from the src_collection
    my @records=$src_mongo->find({}, \%fields)->all;
    $stats->{"$class records"}=scalar @records;
    my $fuse=$options{fuse};
    $stats->{"$class records"}=$fuse unless $fuse==-1;

    foreach my $record (@records) {
	my $geo_id=$record->{geo_id} or next;
	foreach my $field (@$word_fields) {
	    next unless $record->{$field};

	    my @wordlist;
	    if ($options{phrase}) {
		$wordlist[0]=$record->{$field};
	    } elsif (ref $record->{$field} eq 'ARRAY') {
		@wordlist=@{$record->{$field}};
	    } else {
		@wordlist=split(/[^\w]+/, $record->{$field});
	    }

	    foreach my $word (@wordlist) {
		$word2geo->save({geo_id=>$geo_id, word=>$word, source=>$field});
		my $error=GEO->db->last_error({});
		my $report;
		if ($error->{ok} && !$error->{err}) {
		    $report='ok';
		    $stats->{n_inserted}++;
		} else {
		    $report=Dumper($error);
		    $report=~s/\n/, /g;
		    $report=~s/\$VAR1 = //;
		    $stats->{n_errors}++;
		}
		warnf "%s: %s->%s: report=%s\n", $geo_id, $field, $word, $report if $options{v};
	    }
	}
	last if --$fuse==0;
    }
    warn Dumper($stats) unless $options{q};
}


main(@ARGV);
