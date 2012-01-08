package GEO::Dataset;
use Moose;
extends 'GEO';
use MooseX::ClassAttribute;
use Carp;

use GEO::DatasetSubset;


has 'channel_count'            => (is=>'rw', isa=>'Str');
has 'description'              => (is=>'rw', isa=>'Str');
has 'feature_count'            => (is=>'rw', isa=>'Str');
has 'order'                    => (is=>'rw', isa=>'Str');
has 'platform'                 => (is=>'rw', isa=>'Str');
has 'platform_organism'        => (is=>'rw', isa=>'Str');
has 'platform_technology_type' => (is=>'rw', isa=>'Str');
has 'pubmed_id'                => (is=>'rw', isa=>'Str');
has 'reference_series'         => (is=>'rw', isa=>'Str');
has 'sample_count'             => (is=>'rw', isa=>'Str');
has 'sample_organism'          => (is=>'rw', isa=>'Str');
has 'sample_type'              => (is=>'rw', isa=>'Str');
has 'title'                    => (is=>'rw', isa=>'Str');
has 'type'                     => (is=>'rw', isa=>'Str');
has 'update_date'              => (is=>'rw', isa=>'Str');
has 'value_type'               => (is=>'rw', isa=>'Str');

class_has 'collection_name'=> (is=>'ro', isa=>'Str', default=>'datasets');
class_has 'prefix'=> (is=>'ro', isa=>'Str', default=>'GDS');
class_has 'subdir' => (is=>'ro', isa=>'Str', default=>'datasets');
class_has 'word_fields' => (is=>'ro', isa=>'ArrayRef', default=>sub {[qw(title description)]});

# return the path to the .soft file:
sub soft_file {
    my ($self)=@_;
    join('/', $self->data_dir, $self->subdir, join('.', $self->geo_id, 'soft'));
}

# return a list[ref] of GEO::DatasetSubset objects for this dataset:
sub subsets {
    my ($self)=@_;
    my @records=GEO::DatasetSubset->get_mongo_records({dataset_id=>$self->geo_id});
    my @subsets=map {GEO::DatasetSubset->new(%{$_})} @records;
    wantarray? @subsets:\@subsets;
}


# return a list[ref] of SeriesData objects:
sub samples {
    my ($self)=@_;
    my @samples=();
    foreach my $ss ($self->subsets) {
	push @samples, $ss->samples;
    }
    wantarray? @samples:\@samples;
}

sub n_samples { scalar @{shift->samples} }

sub report {
    my ($self)=@_;
    return sprintf("%s: no geo record", $self->geo_id) unless $self->_id;
    my $report=sprintf "%8s: %s\n", $self->geo_id, $self->title;
    $report.=sprintf "    %s\n", $self->description;
    $report.=sprintf "%12s\n", $self->reference_series;

    $report.=sprintf "%12d subsets, %d samples\n", scalar @{$self->subsets}, $self->sample_count;
    foreach my $subset ($self->subsets) {
	$report.=sprintf "    %s\n", $subset->report;
    }
    $report;
}

1;
