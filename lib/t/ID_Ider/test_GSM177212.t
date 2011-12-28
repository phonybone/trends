#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf dief);
use FindBin;
use Test::More qw(no_plan);

use lib "$FindBin::Bin/../..";
use GEO;

our $class='ID_Ider';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $geo_id=shift or die Options::usage(qw(geo_id));

    require_ok($class);
    my $sd=GEO->factory($geo_id);
    isa_ok($sd, 'GEO::SeriesData');
    
    open (FAILED_IDS, ">$FindBin::Bin/failed_ids.$geo_id") or die "Can't open 'failed_ids.$geo_id': $!\n";

    my $data=$sd->datafile;
    open (DATA, $sd->datafile) or dief "Can't open %s: $!\n", $sd->datafile;
    <DATA>;<DATA>;		# burn first two lines
    my $fuse=$options{fuse};
    while (<DATA>) {
	chomp;
	my ($id,$value,$call,$pval,@junk)=split(',');
	my $l=$class->id_id($id);
#	warn "$id: ",Dumper($l);
	if (!is_deeply ($l, ['probe_affy'], "$id: ".join(", ", @$l))) {
	    print FAILED_IDS "$id\n";
	}
	last if --$fuse==0;
    }
    close FAILED_IDS;
}

main(@ARGV);

