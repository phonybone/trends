#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(dief warnf);

use FindBin;
use lib "$FindBin::Bin/../../../lib";

use Test::More qw(no_plan);

our $class='GEO::Sample';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    my $geo_id=shift || 'GSM1339';
    my $sample=GEO::Sample->new($geo_id);
    my $descs=$sample->descriptions; # keeps it in scalar context
#    warn "descriptions for $geo_id:\n$descs\n";

    my %descs=$sample->descriptions; # hash this time
    is ($descs{GDS270}, 'Examination of muscle biopsies from Duchenne muscular dystrophy patients and normal subjects of various age groups. Both mixed groups of patients (5 patient biopsies per group) and individual biopsies analyzed.');

    is ($descs{GDS270_2}, 'normal');
    is ($descs{GDS270_3}, '4 to 13 years');
    is ($descs{GSM1339}, 'Pool of 5 normal female muscle RNA samples age from 4 to 13, Lot batch =  ');


}

main(@ARGV);

