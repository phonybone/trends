package TestPhenos;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use Data::Dumper;

before qr/^test_/ => sub { shift->setup };


sub test_pheno_hash : Testcase {
    my ($self, $geo_id)=@_;
    my $sample=$self->class->new($geo_id);
    my $pheno_hash=$sample->_pheno_hash;
    warn Dumper($pheno_hash);
}

sub test_subset_phenos : Testcase {
    my ($self, $geo_id)=@_;
    my $sample=$self->class->new($geo_id);
    my $pheno_hash=$sample->subset_phenos;
    warn Dumper($pheno_hash);
    
}

__PACKAGE__->meta->make_immutable;

1;
