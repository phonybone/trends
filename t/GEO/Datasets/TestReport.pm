package TestReport;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(TestGEO); # for method attrs, sigh...
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

    my $expected=<<'    EXPECTED';
 GDS2381: title: Atopic dermatitis (HG-U133A)
    description: Analysis of lesional and non-lesional skin biopsy specimens from adult patients with atopic dermatitis (AD). Results provide insight into the molecular changes associated with early AD inflammation.
    reference series: GSE5667
          16 subsets, 17 samples, phenotypes: Wed Oct 17 14:10:04 2012, Tue Oct 16 14:26:46 2012
    GDS2381_1 (5 samples): normal samples=GSM132623, GSM132624, GSM132625, GSM132626, GSM132627
    GDS2381_2 (12 samples): atopic dermatitis samples=GSM132628, GSM132629, GSM132630, GSM132631, GSM132632, GSM132633, GSM132634, GSM132635, GSM132636, GSM132637, GSM132638, GSM132639
    GDS2381_3 (5 samples): control samples=GSM132623, GSM132624, GSM132625, GSM132626, GSM132627
    GDS2381_4 (6 samples): non-lesional samples=GSM132628, GSM132629, GSM132630, GSM132631, GSM132632, GSM132633
    GDS2381_5 (6 samples): lesional samples=GSM132634, GSM132635, GSM132636, GSM132637, GSM132638, GSM132639
    GDS2381_6 (1 samples): healthy 1 samples=GSM132623
    GDS2381_7 (1 samples): healthy 2 samples=GSM132624
    GDS2381_8 (1 samples): healthy 3 samples=GSM132625
    GDS2381_9 (1 samples): healthy 4 samples=GSM132626
    GDS2381_10 (1 samples): healthy 5 samples=GSM132627
    GDS2381_11 (2 samples): patient 1 samples=GSM132628, GSM132634
    GDS2381_12 (2 samples): patient 2 samples=GSM132629, GSM132635
    GDS2381_13 (2 samples): patient 3 samples=GSM132630, GSM132636
    GDS2381_14 (2 samples): patient 4 samples=GSM132631, GSM132637
    GDS2381_15 (2 samples): patient 5 samples=GSM132632, GSM132638
    GDS2381_16 (2 samples): patient 6 samples=GSM132633, GSM132639
    EXPECTED
    chomp $expected;

    warn "badly designed test: will break on weird phenotypes.\n";

#    warn $ds->report;
    cmp_ok($ds->report, 'eq', $expected);
}

__PACKAGE__->meta->make_immutable;

1;
