package TestJson;
use namespace::autoclean;

# Test that it's ok to call to_json on an unbless geo object.

use Moose;
extends 'TestGEO';
use parent qw(TestGEO);
use Test::More;
use GEO;
use JSON;
use Data::Structure::Util qw(unbless);
use Data::Dumper;
use PhonyBone::FileUtilities qw(warnf);

before qr/^test_/ => sub { shift->setup };
sub setup {
    my ($self)=@_;
}

sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class);
}

sub test_json :Testcase {
    my ($self)=@_;
    my @geo_ids=qw(GSE10072 GDS2381 GDS2381_1 GSM132638);
    foreach my $geo_id (@geo_ids) {
	my $geo=GEO->factory($geo_id);
	my $json=eval {to_json(unbless $geo)};
	cmp_ok($@, 'eq', '', 'got json');
#	warn "json is $json\n";

	{
	    local $SIG{__DIE__}=sub {confess @_};
	    my $geo2=from_json($json);
	    my $id1=delete $geo->{_id};
	    my $id2=delete $geo2->{_id};
	    cmp_ok($id1->{value}, 'eq', $id2->{value}, "ids match");
	    is_deeply($geo, $geo2, $geo_id);
	}

    }
}

__PACKAGE__->meta->make_immutable;

1;
