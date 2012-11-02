package GEO::HasSamples;
use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose::Role;
with 'GEO::HasPhenotypes';
has 'sample_ids'  => (is=>'ro', isa=>'ArrayRef[Str]', default=>sub{[]});
has 'samples'    => (is=>'ro', isa=>'ArrayRef[GEO::Sample]', lazy=>1, builder=>'_build_samples');
sub _build_samples { [map {GEO->factory($_)} @{shift->sample_ids}] }
    
sub n_samples { scalar @{shift->sample_ids}; }



1;
