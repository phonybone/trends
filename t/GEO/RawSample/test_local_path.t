#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../../..";

our $class='GEO';
use GEO::RawSample;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    
    my $geo_id='GSM736624';
    my $raw_sample=GEO::RawSample->new(geo_id=>$geo_id);
    
    my $data_dir=GEO->data_dir;
    $geo_id=~/GSM\d\d\d/ or die "malformed sample id '$geo_id'";
    my $subdir=$&;
    is ($raw_sample->path, join('/',$data_dir, $raw_sample->subdir, $subdir, $raw_sample->geo_id), "got path for $geo_id");
    ok (-d $raw_sample->path, "path for $geo_id exists and is a directory");
    
}

main(@ARGV);
