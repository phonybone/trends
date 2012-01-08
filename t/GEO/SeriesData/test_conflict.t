#!/usr/bin/env perl 
#-*-perl-*-

#
# OBSOLETE
# This was meant to test what happens when a RawSample
# and a SeriesData object shared the same geo_id.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../..";

our $class='GEO';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $geo_id='GSM101110';	# known conflicted id

    my $gsm=GEO->factory($geo_id);
    is (ref $gsm, 'GEO::RawSample', "got RawSample $geo_id");
    
    my $gsd=GEO::SeriesData->factory($geo_id);
    is (ref $gsd, 'GEO::SeriesData', "got SeriesData $geo_id");

    # this shouldn't really exist; so is this really the behaviour we want?
    $geo_id='GSM29804';		
    $gsm=GEO->factory($geo_id);
    is (ref $gsm, 'GEO::RawSample', "got RawSample $geo_id");
    is ($gsm->_id, undef, "got undef for missing RawSample");
    
    $gsd=GEO::SeriesData->factory($geo_id);
    is (ref $gsd, 'GEO::SeriesData', "got SeriesData $geo_id");
    is (ref $gsd->_id, 'MongoDB::OID', sprintf("got %s for DataSeries", ref $gsd->_id));
    
}

main(@ARGV);
