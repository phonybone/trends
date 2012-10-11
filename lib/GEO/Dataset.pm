package GEO::Dataset;
use Moose;
use MooseX::ClassAttribute;
use Carp;
use PhonyBone::ListUtilities qw(unique);
use PhonyBone::FileUtilities qw(warnf);
use Data::Dumper;

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

has 'subsets'                  => (is=>'ro', isa=>'ArrayRef[GEO::DatasetSubset]',
				   lazy=>1, builder=>'_build_subsets');
has 'subset_ids'               => (is=>'ro', isa=>'ArrayRef[Str]', 
				   lazy=>1, builder=>'_build_subset_ids');
has 'samples'                  => (is=>'ro', isa=>'ArrayRef[GEO::Sample]',
				   lazy=>1, builder=>'_build_samples');
has 'sample_ids'               => (is=>'ro', isa=>'ArrayRef[Str]', 
				   lazy=>1, builder=>'_build_sample_ids');


class_has 'collection_name'=> (is=>'ro', isa=>'Str', default=>'datasets');
class_has 'prefix'=> (is=>'ro', isa=>'Str', default=>'GDS');
class_has 'subdir' => (is=>'ro', isa=>'Str', default=>'datasets');
class_has 'word_fields' => (is=>'ro', isa=>'ArrayRef', default=>sub {[qw(title description)]});
extends 'GEO';

# return the path to the .soft file:
sub soft_file {
    my ($self)=@_;
    join('/', $self->data_dir, $self->subdir, join('.', $self->geo_id, 'soft'));
}

# return a list[ref] of GEO::DatasetSubset objects for this dataset:
# searches the database.
sub _build_subsets {
    my ($self)=@_;
    my @records=GEO::DatasetSubset->get_mongo_records({dataset_id=>$self->geo_id});
    [map {GEO::DatasetSubset->new(%{$_})} @records];
}
sub _build_subset_ids {
    my ($self)=@_;
    [map {$_->geo_id} @{$self->subsets}];
}

sub n_subsets { scalar @{shift->subsets} }


# return a list[ref] of Sample objects:
sub _build_sample_ids {
    my ($self)=@_;
    my %sample_ids;
    foreach my $ss (@{$self->subsets}) {
	$sample_ids{$_}=$_ for @{$ss->sample_ids};
    }
    [keys %sample_ids];
}

sub _build_samples {
    my ($self)=@_;
    my $sample_ids=$self->sample_ids;
    [map {GEO->factory($_)} @{$self->sample_ids}];
}

sub n_samples { scalar @{shift->samples} }

sub report {
    my ($self)=@_;
    return sprintf("%s: no geo record", $self->geo_id) unless $self->_id;
    my $report=sprintf "%8s: title: %s\n", $self->geo_id, $self->title;
    $report.=sprintf "    description: %s\n", $self->description;
    $report.=sprintf "%12s\n", $self->reference_series;

    $report.=sprintf "%12d subsets, %d samples\n", scalar @{$self->subsets}, $self->sample_count;
    foreach my $subset (@{$self->subsets}) {
	$report.=sprintf "    %s\n", $subset->report;
    }
    $report;
}

1;
