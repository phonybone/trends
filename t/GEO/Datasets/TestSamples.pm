package TestSamples;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use PhonyBone::ListUtilities qw(in_list);
use Data::Dumper;

before qr/^test_/ => sub { shift->setup };


sub test_compiles : Testcase {
    my ($self)=@_;
    my $class=$self->class;
    require_ok($class);
}

sub test_samples : Testcase {
    my ($self)=@_;
    my $geo_id='GDS2381';
    my $ds=GEO->factory($geo_id);

    my $samples=$ds->samples;
#    warn "samples: ", Dumper($samples);
    cmp_ok(scalar @$samples, '==', 17, "17 samples");
    cmp_ok(scalar @$samples, '==', $ds->n_samples);
    my $i=1;
    isa_ok($_, 'GEO::Sample', sprintf "sample %d", $i++) for @$samples;
    my $sample_ids=[map {$_->geo_id} @$samples];

    my $expected=[qw(GSM132623
		     GSM132624
		     GSM132625
		     GSM132626
		     GSM132627
		     GSM132628
		     GSM132629
		     GSM132630
		     GSM132631
		     GSM132632
		     GSM132633
		     GSM132634
		     GSM132635
		     GSM132636
		     GSM132637
		     GSM132638
		     GSM132639
		  )];
    ok(in_list($sample_ids, $_), "found $_") for @$expected;
}


sub test_subsets {
    my ($self)=@_;
    my $geo_id='GDS2381';
    my $ds=GEO->factory($geo_id);

    my $subsets=$ds->subsets;
    cmp_ok(scalar @$subsets, '==', 16, "16 subsets");
    cmp_ok(scalar @$subsets, '==', $ds->n_subsets);
    my $i=1;
    isa_ok($_, 'GEO::DatasetSubset', sprintf "subset %d", $i++) for @$subsets;
    my $subset_ids=[map {$_->geo_id} @$subsets];
    my $expected=[qw(GDS2381_1
		     GDS2381_2
		     GDS2381_3
		     GDS2381_4
		     GDS2381_5
		     GDS2381_6
		     GDS2381_7
		     GDS2381_8
		     GDS2381_9
		     GDS2381_10
		     GDS2381_11
		     GDS2381_12
		     GDS2381_13
		     GDS2381_14
		     GDS2381_15
		     GDS2381_16
		  )];

    ok(in_list($subset_ids, $_), "found $_") for @$expected;
}

__PACKAGE__->meta->make_immutable;

1;
