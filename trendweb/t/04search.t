#!perl
# -*-perl-*-

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../lib");
use lib abs_path($Bin);
use GEO;
use PhonyBone::FileUtilities qw(warnf);

use Catalyst::Test 'trendweb';
use trendweb::Controller::GEO;
our $class='trendweb::Controller::GEO';

use TestSearch;

# not sure why this ain't working; something about "Could not serialize from an empty content-type"
#ok( request('/fart/GDS2381')->is_success, 'Request should succeed' );

sub main {
    my @args=@_;
    GEO->db_name('geo_test');
    warnf "GEO: using %s:%s", GEO->host, GEO->db_name;
    my $tc=TestSearch->new($class);
    $tc->run_all_tests;
    done_testing();
}

main(@ARGV);
