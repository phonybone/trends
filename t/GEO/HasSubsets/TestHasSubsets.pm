package TestHasSubsets;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use Data::Dumper;
use PhonyBone::FileUtilities qw(warnf);
use PhonyBone::ListUtilities qw(in_list);

before qr/^test_/ => sub { shift->setup };


sub test_subsets : Testcase {
    my ($self, $geo_id, $min_ss)=@_;
    my $geo=GEO->factory($geo_id);
    my $subsets=$geo->subsets;
    cmp_ok($geo->n_subsets, ">=", $min_ss, sprintf "%s: got %d subsets", $geo_id, $geo->n_subsets);
    cmp_ok(scalar @$subsets, '==', $geo->n_subsets);
    foreach my $subset (@$subsets) {
	isa_ok($subset, 'GEO::DatasetSubset');
    }
}

sub test_subset_phenos : Testcase {
    my ($self, $geo_id)=@_;
    my $geo=GEO->factory($geo_id);
    my $phenos=$geo->subset_phenos; # k=pheno, v=geo_id
    isa_ok($phenos, 'HASH');
#    warnf "%s: phenos=%s", $geo_id, Dumper($phenos);

    cmp_ok($geo->n_subsets, '==', scalar keys %$phenos, 
	   sprintf "%d=%d %s->subset_phenos", $geo->n_subsets, scalar keys %$phenos, $geo_id);

    # check that every pheno matches a subset
    while (my ($pheno, $geo_id)=each %$phenos) {
	my $ss=GEO->factory($geo_id);
	isa_ok($ss, 'GEO::DatasetSubset');
	cmp_ok($ss->description, 'eq', $pheno, "$geo_id->desc eq '$pheno'");
    }

    # check that every subset matches a pheno:
    foreach my $ss (@{$geo->subsets}) {
	cmp_ok($ss->geo_id, 'eq', $phenos->{$ss->description}, 
	       sprintf "%s->description eq %s", $ss->geo_id, $ss->description);
    }

}

sub test_gds_gsm_pair : Testcase {
    my ($self, $gds_id, $gsm_id)=@_;
    my $gds=GEO->factory($gds_id);
    isa_ok($gds, 'GEO::Dataset', $gds_id);
    my $gsm=GEO->factory($gsm_id);
    isa_ok($gsm, 'GEO::Sample', $gsm_id);
    ok (in_list($gds->sample_ids, $gsm_id), "$gsm_id is a sample for $gds_id") or return;

    my $gds_ss=$gds->subset_ids;
    my $gsm_ss=$gsm->subset_ids;
    foreach my $gsm_s (@$gsm_ss) {
	ok (in_list($gds_ss, $gsm_s), $gsm_s);
    }
}

__PACKAGE__->meta->make_immutable;

1;
