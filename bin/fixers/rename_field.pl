#!/usr/bin/env perl 

#
# rename the series->status field to series->isb_status so that it doesn't conflict with
# geo_status (from the series.soft files)
# Note: you can't run this file once you've loaded the .soft files; otherwise everything'll be buggered.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../../lib";
require "$FindBin::Bin/../mongo_utils.pl";

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my ($db_name, $collection_name, $src, $dst)=@_;
    
    my $mongo=get_mongo($db_name, $collection_name);
    my @records=$mongo->find->all;
    warnf "got %d records\n", scalar @records;
    
    my $fuse=$options{fuse};
    foreach my $record (@records) {
	next unless $record->{$src};
	$record->{$dst}=$record->{$src};
	delete $record->{$src};
	$mongo->update({_id=>$record->{_id}}, $record);
	last if --$fuse==0;
    }
    warnf "%d records updated\n", scalar @records;
}


main(@ARGV);

