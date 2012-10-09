#-*-perl-*-

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use HTTP::Request::Common;

use FindBin;
use Cwd 'abs_path';
use lib abs_path("$FindBin::Bin/../lib");

use Catalyst::Test 'trendweb';
use trendweb::Controller::Classifier;
use Classifier;

sub main {
    test_1();
    test_content();
}

sub test_1 {
    ok( request('/classifier/1')->is_success, 'Request should succeed' );
}

sub test_content {
    my $n=Classifier->mongo->count;

    # change the 'gene_pos' field to 'SLI1' for classifier id=1:
    my $response=request(POST 'http://localhost:3000/classifier/1.html', [id=>1, gene_pos=>'SLI1']);
    is ($response->code, 201);
    is ($response->header('location'), 'http://localhost:3000/classifier/1');
    
    is (Classifier->mongo->count, $n);

    my $classifier=new Classifier(1);
    isa_ok($classifier, 'Classifier');
    is($classifier->id, 1);
    ok($classifier->_id);	# was found
    is($classifier->{gene_pos}, 'SLI1'); # cool, but it might have already been that...

    # ...so change it again:
    my $response=request(POST 'http://localhost:3000/classifier/1.html', [id=>1, gene_pos=>'LKS3']);
    is ($response->code, 201);
    is ($response->header('location'), 'http://localhost:3000/classifier/1');
    
    is (Classifier->mongo->count, $n);

    $classifier=new Classifier(1);	# refetch from db
    isa_ok($classifier, 'Classifier');
    is($classifier->id, 1);
    ok($classifier->_id);	# was found
    is($classifier->{gene_pos}, 'LKS3');


    
}

main();
done_testing();
