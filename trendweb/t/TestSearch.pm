package TestSearch;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use HTTP::Request::Common;
use Catalyst::Test 'trendweb';
use Data::Dumper;

before qr/^test_/ => sub { shift->setup };


sub test_search : Testcase {
    my ($self)=@_;

    my $query={search_term=>'this is really a search'};
    my $request=POST("/geo/search", 
		     Content=>$query,
	);
    my $response=request $request;
    cmp_ok($response->code, '==', 200, sprintf("got code=%s", $response->status_line));
    
}

__PACKAGE__->meta->make_immutable;

1;
