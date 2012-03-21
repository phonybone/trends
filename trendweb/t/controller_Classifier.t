use strict;
use warnings;
use Test::More;


use Catalyst::Test 'trendweb';
use trendweb::Controller::Classifier;

ok( request('/classifier')->is_success, 'Request should succeed' );
done_testing();
