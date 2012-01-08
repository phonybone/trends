#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
# This script looks through all the datasets and reports whether or not the corresponding 
# series has been downloaded.

use Options;
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use GEO;

BEGIN: {
  Options::use(qw(d q v h fuse=i fix_status));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    my @gses=map{$_->{geo_id}} GEO::Series->get_mongo_records({status=>'pending download'});
    warnf "got %d pending series\n", scalar @gses;
    foreach my $gse (@gses) { print "$gse\n"; }
}

main(@ARGV);
