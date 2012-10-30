package TestGEO;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use File::Spec;
use PhonyBone::FileUtilities qw(warnf);

use GEO;

my $data_dir=File::Spec->catfile($ENV{TRENDS_HOME}, 't', 'fixtures', 'data', 'GEO');
GEO->data_dir($data_dir);
GEO->db_name('geo_test');
warnf "TestGEO: using %s\n", GEO::Series->mongo_coords;
before qr/^test_/ => sub { shift->setup };


__PACKAGE__->meta->make_immutable;

1;
