use strict;
use warnings;
use Test::More;


use Catalyst::Test 'trendweb';
use trendweb::Controller::GEO;

ok( request('/geo')->is_success, 'Request should succeed' );
done_testing();