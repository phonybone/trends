package TestFactory;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(TestGEO); # for method attrs, sigh...
use Test::More;

use GEO;
use Data::Dumper;

before qr/^test_/ => sub { shift->setup };


sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class);
}

sub test_geo : Testcase {
    my ($self, $geo_id)=@_;
    my $geo=GEO->factory($geo_id);
    cmp_ok($geo->geo_id, 'eq', $geo_id, $geo_id);
}

__PACKAGE__->meta->make_immutable;

1;
