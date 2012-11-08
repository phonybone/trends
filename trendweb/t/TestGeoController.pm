package TestGeoController;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use Catalyst::Test 'trendweb';
use HTTP::Request::Common;
use Data::Dumper;
use JSON;
use Data::Structure::Util qw(unbless);
use PhonyBone::FileUtilities qw(warnf spitString);
use PhonyBone::ListUtilities qw(in_list);
use URI::Escape;
#use Test::WWW::Mechanize::Catalyst;

before qr/^test_/ => sub { shift->setup };

# why ain't this working?
sub setup {
    warn "setup: duck hi!";
}

sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class);
}

sub test_get : Testcase {
    my ($self)=@_;
    foreach my $geo_id (qw(GDS2381_1 GDS2381 GSE10072 GSM30421)) {
	my $request=GET "/geo/$geo_id", 'Content-type' => 'application/json';
	my $response=request $request;
	ok($response->is_success, sprintf "GET $geo_id: %s", $response->status_line) or next;
	my $record=from_json($response->content);
	cmp_ok($record->{geo_id}, 'eq', $geo_id);
    }
}

sub test_post : Testcase {
    my ($self)=@_;
    my $geo_id='GSE1743';
    my $series=GEO->factory($geo_id);
    isa_ok($series, 'GEO::Series');
    cmp_ok($series->{geo_id}, 'eq', $geo_id);
    my $new_title='Johnathan Buttercakes III';
    $series->{title}=$new_title;
    my $record=unbless($series);
    delete $record->{_id};

    my $request=POST("/geo/$geo_id", 
		     'Content-type' => 'application/json',
		     Content=>to_json($series),
	);
#    warnf "request is %s", $request->as_string;

    my $response=request $request;
    ok($response->is_success, $geo_id) or
	spitString($response->content, "tc.out");
#    warnf "POST(%s): content is %s", $response->status_line, $response->content;

    my $new_series=GEO->factory($geo_id);
#    warnf "new series is %s", Dumper($new_series);
    cmp_ok($new_series->{title}, 'eq', $new_title);
}

sub test_bulk_POST : Testcase {
    my ($self)=@_;
    my $ds_id='GDS2381';
    my $ds=GEO->factory($ds_id);
    my $sample_ids=$ds->sample_ids;
    my @samples=map {GEO->factory($_)} @$sample_ids;
    my $pheno=scalar localtime;	# get a time stamp
    my @records;
    foreach my $sample (@samples) {
	$sample->phenotypes([$pheno]); # set phenotype list
	delete $sample->{_id};
	push @records, unbless($sample);
    }
    my $json=to_json(\@records);
    my $request=POST("/geo/bulk", 
		     'Content-type' => 'application/json',
		     Content=>$json,
	);
    my $response=request $request;
    ok($response->is_success, sprintf "%s %s: %s", $request->method, $request->uri, $response->status_line);
    
    # verify edits made:
    foreach my $sample_id (@$sample_ids) {
	my $sample=GEO->factory($sample_id);
	cmp_ok(scalar @{$sample->phenotypes}, '==', 1);
	ok(in_list($sample->phenotypes, $pheno), 
	   sprintf("%s: '%s' in ['%s']", $sample->geo_id, $pheno, join("', '", @{$sample->phenotypes})));
    }
}

sub test_404 : Testcase {
    my ($self)=@_;
    my $geo_id='G81';		# malformed
    my $request=GET "/geo/$geo_id", 'Content-type' => 'application/json';
    my $response=request $request;
    isa_ok($response, 'HTTP::Response');
    cmp_ok($response->code, '==', 404, "got 404 on $geo_id");
}


# sub test_delete : Testcase {
#     my ($self)=@_;
#     my $request=DELETE("/geo/$geo_id");
#     my $response=request $request;
    
# }

__PACKAGE__->meta->make_immutable;

1;
