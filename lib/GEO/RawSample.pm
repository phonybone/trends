package GEO::RawSample;
use Moose;
extends 'GEO';
use MooseX::ClassAttribute;
use Carp;
use Data::Dumper;
use PhonyBone::FileUtilities qw(warnf);

has 'path_raw_data' => (is=>'rw', isa=>'Str');
has 'series_ids'    => (is=>'rw', isa=>'ArrayRef', default=>sub{[]});
has 'dataset_id'    => (is=>'rw', isa=>'Str');
has 'subset_id'     => (is=>'rw', isa=>'Str');
has 'phenotype'     => (is=>'rw', isa=>'Str');
#has '_iter'        => (is=>'rw', isa=>'GEO::RawSample::Iterator');

class_has 'collection'=> (is=>'ro', isa=>'Str', default=>'raw_samples');
class_has 'prefix'    => (is=>'ro', isa=>'Str', default=>'GSM' );
class_has 'subdir'    => (is=>'ro', isa=>'Str', default=>'sample_data');

sub report {
    my ($self)=@_;
    my $report=sprintf "%s (Raw Sample):\n   path: %s\n", $self->geo_id, $self->path;
    $report.=sprintf("   Series ids: %s\n", join(', ', @{$self->series_ids}));
    if ($self->path_raw_data) {
	$report.=sprintf("   Raw Data: %s\n", $self->path_raw_data);
    }
    $report;
}

# return the list of series objects for the sample
sub series_list {			# plural
    my ($self)=shift;
    my @series=map {GEO::Series->new($_)} @{$self->series_ids};
    wantarray? @series:\@series;
}

# see also $self->path_raw_data
sub path {
    my ($self)=@_;
    my $ssubdir=substr($self->geo_id,0,6);
    return join('/', $self->data_dir, $self->subdir, $ssubdir);
}


1;
