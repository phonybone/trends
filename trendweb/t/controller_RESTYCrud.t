use strict;
use warnings;
use Test::More;


use Catalyst::Test 'trendweb';
use trendweb::Controller::RESTYCrud;

ok( request('/restycrud')->is_success, 'Request should succeed' );
done_testing();
