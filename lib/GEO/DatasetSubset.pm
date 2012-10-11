package GEO::DatasetSubset;
use Moose;
use MooseX::ClassAttribute;


has 'dataset_id' => (is=>'rw', isa=>'Str');
has 'description' => (is=>'rw', isa=>'Str');
sub title { shift->description } # Is there a better way to do this?
has 'sample_ids' => (is=>'rw', isa=>'ArrayRef[Str]');
has 'samples' => (is=>'rw', isa=>'ArrayRef[GEO::Sample]', lazy=>1, builder=>'_build_samples');
has 'type' => (is=>'rw', isa=>'Str');



class_has 'collection_name'=> (is=>'ro', isa=>'Str', default=>'dataset_subsets');
class_has 'prefix'    => (is=>'ro', isa=>'Str', default=>'GDS_SS');
class_has 'word_fields' => (is=>'ro', isa=>'ArrayRef', default=>sub {[qw(description)]});
extends 'GEO';

sub n_samples { scalar @{shift->sample_ids} }

# return a list[ref] of Sample objects for this subset
sub _build_samples {
    my ($self)=@_;
    [map { GEO->factory($_) } @{$self->sample_ids}];
}

sub report {
    my ($self)=@_;
    sprintf "%s (%d samples): %s samples=%s", $self->geo_id, $self->n_samples, $self->description, 
    join(', ', @{$self->sample_ids});
}


1;
