package TestAllPhenos;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use GEO;
use Data::Dumper;
use PhonyBone::FileUtilities qw(warnf);
use PhonyBone::ListUtilities qw(in_list);

before qr/^test_/ => sub { shift->setup };


sub test_all_phenos : Testcase {
    my ($self, $gds_id)=@_;
    my $gds=GEO->factory($gds_id);
    isa_ok($gds, 'GEO::Dataset') or return;

    # check that all_phenos contains all the phenos from the subsets and the samples:
    my $subset_phenos=[keys %{$gds->subset_phenos}]; # hash
#    warn "$gds_id: subset_phenos are ", Dumper($subset_phenos);
    my $sample_phenos=$gds->phenotypes;	     # array
#    warn "$gds_id: sample_phenos are ", Dumper($sample_phenos);
    my $all_phenos=$gds->all_phenotypes;     # array
    warn "$gds_id: all_phenos: ", Dumper($all_phenos);

    # check $all_phenos in one of samples or subsets:
    foreach my $pheno (@{$all_phenos}) {
	ok (in_list($subset_phenos, $pheno) || in_list($sample_phenos, $pheno), 
	    "$pheno is subset or samples");
    }

    # check all subset phenos in $all_phenos
    foreach my $pheno (@$subset_phenos) {
	ok (in_list($all_phenos, $pheno), "subset $pheno in all_phenos");
    }
    # check all sample phenos in $all_phenos
    foreach my $pheno (@$sample_phenos) {
	ok (in_list($all_phenos, $pheno), "sample $pheno  in all_phenos");
    }
}

__PACKAGE__->meta->make_immutable;

1;
