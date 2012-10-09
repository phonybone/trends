package TestJson;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase);
use Test::More;
use GEO;

my $desc=<<"DESC";
This test is now obsolete since GEO objects are no longer responsible for
serializing themselves.  In fact, the test will break on the missing 'json()' 
method.
DESC

    has 'description' => (is=>'ro', isa=>'Str', default=>$desc);


before qr/^test_/ => sub { shift->setup };


sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class);
}

sub test_json :Testcase {
    my ($self)=@_;
    my $geo_id='GSE10072';
    my $series=GEO->factory($geo_id);
    isa_ok($series, 'GEO::Series');
    my $json=$series->json('localhost');
    warn "json is $json\n";
}

__PACKAGE__->meta->make_immutable;

1;
