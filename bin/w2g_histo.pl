#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;			# PhonyBone::Options, sorta

use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib abs_path("$Bin/../lib");
use GEO::word2geo;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my @args=@_;

    # get all records from word2geo
    my $histo=GEO::word2geo->histo;

    my @sorted=sort keys %$histo;
    foreach my $word (@sorted) {
	my $geo_ids=$histo->{$word};
	printf "%20s: %s\n", $word, join(', ', sort @$geo_ids);
    }
}

main(@ARGV);

