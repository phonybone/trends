#!/usr/bin/env perl 

#
# Create a histogram of words based on the descriptions found in the datasets db (including subsets)
# Maybe useful for ds->pheno.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::word2geo;

require "$FindBin::Bin/mongo_utils.pl";


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $w2g=get_mongo('geo', 'word2geo');
    my $records=get_all($w2g);
    my $histo=make_histo($records);
    report($histo, 'by_freq');
}

sub get_all {
    my ($w2g)=@_;
    my @records=$w2g->find({}, {_id=>0})->all;
    wantarray? @records:\@records;
}

sub make_histo {
    my ($records)=@_;
    my %histo;
    foreach my $record (@$records) {
	my $word=$record->{word};
	$histo{$word}++;
    }
    wantarray? %histo:\%histo;
}

# print a report of the histo
# sort on either or word (alphabetically) or frequency
sub report {
    my ($histo, $order)=@_;
    $order||='by_freq';

    my @keys;
    if ($order eq 'by_freq') {
	@keys=map {$_->[0]} sort {$b->[1] <=> $a->[1]} map{[$_, $histo->{$_}]} keys %$histo;
    } else {
	@keys=sort keys %$histo;
    }
    foreach my $k (@keys) {
	printf "%30s: %d\n", $k, $histo->{$k};
    }
}

main(@ARGV);
