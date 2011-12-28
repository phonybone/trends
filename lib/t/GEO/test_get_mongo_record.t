#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../..";

our $class='GEO';

use PhonyBone::FileUtilities qw(warnf);

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);

    test_object_call();
    test_class_call();
    test_cross_class();
    test_missing_geo_id();
    test_bad_geo_id();
}


# call get_mongo_records as a instance method:
sub test_object_call {
    my $rs_id='GSM643865';
    my $rs=GEO::RawSample->new($rs_id);	# calls get_mongo_record from BUILD/constructor
#    warn "rs is ", Dumper($rs);
    isa_ok($rs, 'GEO::RawSample', 'got RawSample');
    is ($rs->geo_id, $rs_id, "got geo_id=$rs_id");
    is ($rs->path, '/proj/hoodlab/share/vcassen/trends/data/GEO/series/GSE26226/GSM643865.CEL.gz', "got path");
}

# call get_mongo_records as a class method:
sub test_class_call {
    my $ds_id='GDS913';
    my $record=GEO->get_mongo_record($ds_id);
    isa_ok($record, 'HASH');
    is ($record->{geo_id}, $ds_id, 'got geo_id');
    is ($record->{title}, 'DNA damage from ultraviolet and ionizing radiation effect on peripheral blood lymphocytes', 'got title');
    is ($record->{pubmed_id}, 15356296, 'got pubmed_id');
    is ($record->{platform_technology_type}, "in situ oligonucleotide", 'got platform tech type');
    # there are more, but that should be enough for a positive id
}

# test the use of the $class parameter:
sub test_cross_class {
    # first get a SeriesData object through which to issue the call
    my $sd_id='GSM29804';		# this is a SeriesData id, not a RawSample
    my $ds_id='GDS913';		# dataset id
    my $sd=GEO->factory($sd_id, 'GEO::SeriesData');
    isa_ok($sd, 'GEO::SeriesData', "got a SeriesData object for $sd_id");
#    warn Dumper($sd);
    is ($sd->dataset_id, $ds_id, "got dataset_id=$ds_id");

    my $record=$sd->get_mongo_record($ds_id, 'GEO::Dataset');
#    warn "record is ",Dumper($record);
    isa_ok($record, 'HASH');
    is ($record->{geo_id}, $ds_id, 'got geo_id');
    is ($record->{title}, 'DNA damage from ultraviolet and ionizing radiation effect on peripheral blood lymphocytes', 'got title');
    is ($record->{pubmed_id}, 15356296, 'got pubmed_id');
    is ($record->{platform_technology_type}, "in situ oligonucleotide", 'got platform tech type');
    # there are more, but that should be enough for a positive id
}


sub test_missing_geo_id {
    eval { my $record=GEO->get_mongo_record() };
    like ($@, qr(no geo_id), "caught missing geo_id");
}

sub test_bad_geo_id {
    my $record=GEO->get_mongo_record('blah', 'GEO::RawSample');
    is ($record, undef, "got undef for no matching record");
}

main(@ARGV);

