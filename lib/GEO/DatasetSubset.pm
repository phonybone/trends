package GEO::DatasetSubset;
use Moose;
extends 'GEO';
use MooseX::ClassAttribute;


has 'dataset_id' => (is=>'rw', isa=>'Str');
has 'description' => (is=>'rw', isa=>'Str');
has 'sample_id' => (is=>'rw', isa=>'Str'); # should have been 'sample_ids'
has 'type' => (is=>'rw', isa=>'Str');

class_has 'collection_name'=> (is=>'ro', isa=>'Str', default=>'dataset_subsets');
class_has 'prefix'    => (is=>'ro', isa=>'Str', default=>'GDS_SS');
class_has 'word_fields' => (is=>'ro', isa=>'ArrayRef', default=>sub {[qw(description)]});

sub sample_ids {
    my ($self)=@_;
    my @s_ids=split(/\s*,\s*/, ($self->sample_id||''));
    wantarray? @s_ids:\@s_ids;
}

sub n_samples { scalar @{shift->sample_ids} }


# return a list[ref] of SeriesData objects for this subset
sub samples {
    my ($self)=@_;
    my @SDs=map { new GEO::SeriesData($_) } @{$self->sample_ids};
    wantarray? @SDs:\@SDs;
}

# alias for above
sub series_data_objs { $_[0]->samples }

sub report {
    my ($self)=@_;
    sprintf "%s (%d samples): %s", $self->geo_id, $self->n_samples, $self->description;
}


1;
