package GEO::Dataset;
use Moose;
with qw(GEO::HasSamples GEO::HasSubsets);
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
has 'sample_ids'               => (is=>'ro', isa=>'ArrayRef', lazy=>1, builder=>'_build_sample_ids');
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
extends 'GEO';

# return the path to the .soft file:
sub soft_file {
    my ($self)=@_;
    join('/', $self->data_dir, $self->subdir, join('.', $self->geo_id, 'soft'));
}

has 'subset_ids'  => (is=>'ro', isa=>'ArrayRef[Str]', lazy=>1, builder=>'_build_subset_ids');
sub _build_subset_ids {
    my ($self)=@_;
    [map {$_->{geo_id}} GEO::DatasetSubset->get_mongo_records({dataset_id=>$self->geo_id})];
}



# override GEO::HasSamples::_build_sample_ids: gather all from subsets:
sub _build_sample_ids {
    my ($self)=@_;
    my %sample_ids;
    foreach my $ss (@{$self->subsets}) {
	$sample_ids{$_}=$_ for @{$ss->sample_ids};
    }
    [keys %sample_ids];
};




sub report {
    my ($self)=@_;
    return sprintf("%s: no geo record", $self->geo_id) unless $self->_id;
    my @report;
    push @report, sprintf "%8s: title: %s", $self->geo_id, $self->title;
    push @report, sprintf "    description: %s", $self->description;
    push @report, sprintf "    reference series: %s", $self->reference_series;

    push @report, sprintf "%12d subsets, %d samples",
        scalar @{$self->subsets}, $self->sample_count;

    push @report, sprintf "    assigned phenos: %s", join(', ',@{$self->phenotypes});
    push @report, sprintf "    subset phenos: %s", join(', ', $self->subset_phenos);

    foreach my $subset (@{$self->subsets}) {
	push @report, sprintf "    %s", $subset->report;
    }
    join("\n", @report);
}

# return a list of phenotypes gathered from subsets and assigned to dataset's samples:
sub all_phenotypes1 {
    my ($self)=@_;
    my @phenos=keys %{$self->subset_phenos};
    push @phenos, map {@{$_->phenotypes}} @{$self->samples};
#    @phenos;
    wantarray? @phenos:\@phenos;
}

1;
