#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Test::More qw(no_plan);
use FindBin;

use Options;
use lib "$FindBin::Bin/../..";
use GEO::Series;

BEGIN: {
    Options::use(qw(d q v h fuse=i));
      Options::useDefaults(fuse => -1);
      Options::get();
      die Options::usage() if $options{h};
      $ENV{DEBUG} = 1 if $options{d};
  }


sub main {
    test_series('GSE10072',1);
    test_series('GSE10073',undef); # record doesn't exist
    test_series('GSE6967', undef); # record exists, soft_family doesn't
}

sub test_series {
    my ($geo_id, $expected)=@_;
    $expected='undefined' unless defined $expected;
    my $series=new GEO::Series($geo_id);
    my $filename=$series->softfile;

    my $ok=already_processed($filename);
    $ok='undefined' unless defined $ok;
    is($ok, $expected, "already_processed($filename)=$ok");
}


sub already_processed {
    my ($filename)=@_;
    
    # get gse and Series:
    $filename=~/GSE\d+/ or die "bad filename: $filename";

    my $gse=$&;
    my $series=GEO->factory($gse);
    return undef unless $series->_id; 
    warn "$gse has _id\n";

    # check db for samples in db:
    my $sample_ids=$series->sample_ids or return undef;
    foreach my $sample_id (@$sample_ids) {
	my $sample=GEO->factory($sample_id);
	return undef unless $sample->_id;
	warn "$sample_id has _id\n";
	return undef unless -e $sample->data_table_file;
	warn "$sample_id has data table file\n";
	}

    return 1;
}

main(@ARGV);
