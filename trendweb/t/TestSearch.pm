package TestSearch;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use HTTP::Request::Common;
use Catalyst::Test 'trendweb';
use Data::Dumper;
use JSON;
use PhonyBone::FileUtilities qw(warnf);

before qr/^test_/ => sub { shift->setup };


sub test_search : Testcase {
    my ($self, $st)=@_;
    warn "test_search($st) entered";

    my $query={search_term=>$st};
    my $request=POST("/geo/search", 
		     Content=>$query,
	);
    my $response=request $request;
    cmp_ok($response->code, '==', 200, sprintf("got code=%s", $response->status_line));

    my $content=$response->content;
    ok ($content =~ /(\d+) Search Results for '(.*)'/);
    my ($n_results, $found_st)=($1,$2);
    cmp_ok ($n_results, '>=', 0, "$n_results results");
    cmp_ok ($found_st, 'eq', $st);
}

sub test_search_json :Testcase {
    my ($self, $st, $min_n_results)=@_;
    my $query={search_term=>$st};
    my $json=to_json($query);
    my $request=POST("/geo/search", 
		  'Content-type' => 'application/json',
		  Content=>$json
	);
    my $response=request $request;
    cmp_ok($response->code, '==', 200, sprintf("got code=%s", $response->status_line)) or return;
    
    my $results=from_json($response->content);
    isa_ok($results, 'HASH') or return;
    my $n_results=scalar keys %$results;
    cmp_ok($n_results, '>=', $min_n_results, "$n_results >= $min_n_results results for '$st'");
}

__PACKAGE__->meta->make_immutable;

1;
