#!/usr/bin/env perl 

#
# For a given geo collection (or class), use fields specified by class->word_fields
# to connect all relevent words to this geo_id.  Store in the word2geo collection.
# 
# Usage: perl word2geo.pl <class>
# 

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;

use Options;
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;
use GEO::word2geo;
require 'mongo_utils.pl';


BEGIN: {
  Options::use(qw(d q v h fuse=i db_name=s));
    Options::useDefaults(fuse => -1, db_name=>'geo');
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    $options{v}=1 if $options{d};
    warnf "writing to %s.word2geo\n", $options{db_name};
    GEO->db_name($options{db_name});
}

sub main {
    my $class=shift or die usage(qw([class]));
    $class='GEO::'.$class unless $class=~/^GEO::/;

    my $word2geo=get_mongo($options{db_name}, 'word2geo');
    my $src_mongo=$class->mongo;
    my $word_fields=$class->word_fields;

    # build the fields hash used in the mongo query:
    my %fields;
    @fields{@$word_fields}=@$word_fields;

    # get all the records from the src_collection
    my @records=$src_mongo->find({}, \%fields)->all;
    my $fuse=$options{fuse};
    foreach my $record (@records) {
	my $geo_id=$record->{geo_id} or next;
	foreach my $field (@$word_fields) {
	    next unless $record->{$field};
	    foreach my $word (split(/[^\w]+/, $record->{$field})) {
		$word2geo->insert({geo_id=>$geo_id, word=>$word});
		my $error=GEO->db->last_error({});
		my $report;
		if ($error->{ok} && !$error->{err}) {
		    $report='ok';
		} else {
		    $report=Dumper($error);
		    $report=~s/\n/, /g;
		    $report=~s/\$VAR1 = //;
		}
		warnf "%s->%s: report=%s\n", $geo_id, $word, $report if $options{v};
	    }
	}
	last if --$fuse==0;
    }
}


main(@ARGV);
