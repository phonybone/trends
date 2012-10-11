package TestReport;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use GEO;

before qr/^test_/ => sub { shift->setup };


sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class);
}

sub test_report : Testcase {
    my ($self)=@_;
    my $geo_id='GDS2381';
    my $ds=GEO->factory($geo_id);
    warn $ds->report;
}

__PACKAGE__->meta->make_immutable;

1;
