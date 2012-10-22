package TestBasic;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(TestGEO); # for method attrs, sigh...
use Test::More;

before qr/^test_/ => sub { shift->setup };


sub test_basic : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    
}

__PACKAGE__->meta->make_immutable;

1;
