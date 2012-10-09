#!/usr/bin/env perl 

# Convert a .soft file (GEO Series data) into a .csv file
# suitable for feeding into AUREA.
# 
# .csv format:
# First line is 'ID_REF', 'IDENTIFIER', then one entry for each sample formatted like this:
# join('.', $soft_filename, $sample_id) (or something close to that).
# All following lines consist of the probe_id, the gene symbol, and the expression value
# for the corresponding sample


use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;			# PhonyBone::Options, sorta

use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib abs_path("$Bin/../lib");

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1,
	);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

# The

sub main {
    my @args=@_;
    foreach my $arg (@args) {
	my $filename;
	if ($arg=~/^GSE\d+$/) {
	    my $series=GEO::Series->new($arg);
	    $filename=$series->soft_path;
	} elsif ($arg=~/^GDS\d+$/) {	
	    my $series=GEO::Dataset->new($arg);
	    $filename=$series->soft_file;
	} else {
	    $filename=$arg;
	}

	my $s2c=new Soft2CSV($filename);
	my $output=$s2c->write;
	warn "$output written\n";
    }
    
}

main(@ARGV);

