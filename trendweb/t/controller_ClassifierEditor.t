use strict;
use warnings;
use Test::More;


use Catalyst::Test 'trendweb';
use trendweb::Controller::ClassifierEditor;

ok( request('/classifiereditor')->is_success, 'Request should succeed' );
done_testing();
