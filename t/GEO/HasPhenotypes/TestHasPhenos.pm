package TestHasPhenos;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use PhonyBone::FileUtilities qw(warnf);
use PhonyBone::ListUtilities qw(in_list);
use Data::Dumper;
use GEO;

before qr/^test_/ => sub { shift->setup };


sub show_phenos {
    my ($self, $geo_id)=@_;
    my $geo=GEO->factory($geo_id);
    my $phenos=$geo->phenotypes;
    warnf "$geo_id->phenotypes: %s", Dumper($phenos);
}

sub test_gsm_phenos_in_gds : Testcase {
    my ($self, $gds_id, $gsm_id)=@_;
    my $gds=GEO->factory($gds_id);
    isa_ok($gds, 'GEO::Dataset', $gds_id);
    my $gsm=GEO->factory($gsm_id);
    isa_ok($gsm, 'GEO::Sample', $gsm_id);
    ok (in_list($gds->sample_ids, $gsm_id), "$gsm_id is a sample for $gds_id") or return;

    # # test ss phenos:
    # foreach my $gds_ss (@{$gds->subsets}) {
    # 	ok ($gds->has_pheno($g
    # }

    # # test sample phenos:
    # foreach my $pheno (@{$gsm->phenotypes}) {
	
    # }
}

__PACKAGE__->meta->make_immutable;

1;
