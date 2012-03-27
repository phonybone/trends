#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../lib";

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
    test_basic($geo_id);
    test_missing_record();
}


sub test_basic {
    my ($geo_id)=@_;
    my $series=GEO::Series->new(geo_id=>$geo_id);
    my $record=$series->get_mongo_record;
    is(ref $record, 'HASH', "got the hash for $geo_id");
    is($series->geo_id, $geo_id, "got $geo_id in record");

    # check to see if $series matches $record:
    while (my ($k,$v)=each %$record) {
	next if $k eq 'samples'; # samples is list, see below
	next unless $series->can($k);
	if (ref $v) {
	    is_deeply ($series->$k, $v, "got $k=$v");
	} else {
	    is ($series->$k, $v, "got $k=$v");
	}
    }

}

sub test_missing_record {
    my $series=GEO::Series->new(geo_id=>'GSE1');
    my $record=$series->get_mongo_record;
    is ($record, undef, "got undef for non-existant record");
}

main(@ARGV);

