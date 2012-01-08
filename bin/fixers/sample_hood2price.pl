#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::Series;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my @samples=GEO::RawSample->get_mongo_records({});
    warnf "got %d samples\n", scalar @samples;
    my $mongo=GEO::RawSample->mongo;
    warnf "got mongo %s", $mongo->{name};

    my $fuse=$options{fuse};
    foreach my $record (@samples) {
	my $path=$record->{path} or next;
	$path=~s|/proj/hoodlab/share|/proj/price1|;
	$record->{path}=$path;
	$mongo->update({geo_id=>$record->{geo_id}}, $record);
	warn Dumper($record) if $ENV{DEBUG};
	last if --$fuse==0;
    }
}



main(@ARGV);

