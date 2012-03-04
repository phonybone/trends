use strict;
use warnings;
use Test::More;


use Catalyst::Test 'trendweb';
use trendweb::Controller::Series;

ok( request('/series')->is_success, 'Request should succeed' );
done_testing();
