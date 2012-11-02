package GEO::HasSubsets;
use Carp;
use Data::Dumper;
use PhonyBone::FileUtilities qw(warnf);

use namespace::autoclean;

use Moose::Role;
with 'GEO::HasPhenotypes';
has 'subset_ids'  => (is=>'ro', isa=>'ArrayRef[Str]', default=>sub{[]});
has 'subsets' => (is=>'ro', isa=>'ArrayRef[GEO::DatasetSubset]', lazy=>1, builder=>'_build_subsets');
sub _build_subsets { [map {GEO->factory($_)} @{shift->subset_ids}] }
    
sub n_subsets { scalar @{shift->subset_ids}; }

# return a hash[ref] of permissible phenotypes derived from the sample's ds_subsets:
# k=pheno, v=subset id
# These don't make real sense for samples... but I guess it doesn't hurt, either. 
# (could move these routines, and their tests, to GEO::Dataset.pm)
sub subset_phenos {
    my ($self)=@_;
    my %hash=map {($_->description, $_->geo_id)} @{$self->subsets};
    wantarray? %hash:\%hash;
}
sub is_subset_pheno {
    my ($self, $pheno)=@_;
    $self->subset_phenos->{$pheno};
}



1;
