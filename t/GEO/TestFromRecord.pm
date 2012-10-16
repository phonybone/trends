package TestFromRecord;
use namespace::autoclean;

use Moose;
extends 'PhonyBone::TestCase';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use Data::Structure::Util qw(unbless);
use Data::Dumper;

before qr/^test_/ => sub { shift->setup };


sub test_from_record : Testcase {
    my ($self)=@_;
    my $geo_id='GSM132638';
    my $sample=GEO->factory($geo_id);
    my $ts=scalar localtime;
    $sample->phenotypes([$ts]);
    $sample->save;

    # check that update took:
    $sample=GEO->factory($geo_id);
    is_deeply($sample->phenotypes, [$ts], "saved '$ts' as phenotype");

    # Build a new sample using from_record() that only differs in phenotypes:
    my $record=unbless $sample;
    my $pheno='spots';
    $record->{phenotypes}=[$pheno];
    my $s2=GEO->from_record($record);
    isa_ok($s2->phenotypes, 'ARRAY');
    cmp_ok(scalar @{$s2->phenotypes}, '==', 1);
    cmp_ok($s2->phenotypes->[0], 'eq', $pheno, 
	   sprintf "from_record: phenos=['%s']", join("', '", @{$s2->phenotypes}));
}

__PACKAGE__->meta->make_immutable;

1;
