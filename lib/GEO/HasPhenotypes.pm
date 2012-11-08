package GEO::HasPhenotypes;
use Carp;
use Data::Dumper;
use PhonyBone::FileUtilities qw(warnf);
use namespace::autoclean;

use Moose::Role;

has 'phenotypes' => (is=>'ro', isa=>'ArrayRef[Str]', lazy=>1, builder=>'_build_phenotypes');
sub n_phenotypes { scalar @{shift->phenotypes} }

# gather assigned phenos via samples:
sub _build_phenotypes { [keys %{shift->_pheno_hash}] }


# iterate over all samples to find assigned phenos:
has '_pheno_hash' => (is=>'ro', isa=>'HashRef', lazy=>1, builder=>'_build__pheno_hash');
sub _build__pheno_hash {
    my ($self)=@_;
    my %phenos;
    my $samples=$self->can('samples')? $self->samples : [$self];
    foreach my $sample (@$samples) {
	$phenos{$_}=$_ for @{$sample->phenotypes}; # note: GEO::Sample overrides phenotypes()
    }

    if (0) {			# not sure if this is really correct here...
	my $subsets=$self->can('subsets')? $self->subsets : [];
	foreach my $ss (@$subsets) {
	    my $pheno=$ss->description;
	    $phenos{$pheno}=$pheno;
	}
    }

    \%phenos;
}

# This checks *assigned* phenos (not subset phenos)
sub has_pheno {
    my ($self, $pheno)=@_;
    exists $self->_pheno_hash->{$pheno};
}



1;
