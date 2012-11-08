#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use LWP::UserAgent;

use FindBin;
use lib "$FindBin::Bin";
use lib "$ENV{TRENDS_HOME}/lib";
use ParseSoft;

use GEO;
our $class='GEO::Platform';



BEGIN: {
    Options::use(qw(d q v h fuse=i db_name=s));
    Options::useDefaults(fuse => -1, db_name=>'test_geo');
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO->db_name($options{db_name});
}


sub main {
    require_ok($class);

    my $gpl96_file="$FindBin::Bin/GPL96.soft";
    my $p=ParseSoft->new($gpl96_file);
    my $records=$p->parse;
    is(scalar @$records, 1, "got one record");

    my $record=$records->[0];
    isa_ok($record, 'platform');

    my $gpl=$class->new(%$record);
    isa_ok($gpl, $class, "got a $class");
    my $geo_id=$gpl->geo_id;
    is($geo_id, 'GPL96', "got geo_id=$geo_id");

    # remove from test db:
    my $report=$class->mongo->remove({geo_id=>$geo_id}, {safe=>1});
    is($report->{ok}, 1);
    is($report->{err}, undef);
    
    # Insert and check that the insert was sucessful
    $gpl->insert({safe=>1});
    $record=$class->get_mongo_record($geo_id);
    is($record->{contact_web_link}, 'http://www.affymetrix.com/index.affx', "got contact_web_link");

    # Insert again
    eval {
	$gpl->insert({safe=>1});
    }; 
    like($@, qr/E11000 duplicate key error/, "got correct error message on second insertion");


}

main(@ARGV);

