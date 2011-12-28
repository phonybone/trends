package GEO::SeriesData;
use Moose;
extends 'GEO';
use MooseX::ClassAttribute;

use Data::Dumper;
use File::Spec;
use PhonyBone::FileUtilities qw(warnf dief);

#
# Class to model series data 
#
# Problems: geo_ids conflict in format (/GSM\d+/); don't know if actual
# values overlap or not.
#

has 'dataset_id'      => (is=>'rw', isa=>'Str');
has 'title'           => (is=>'rw', isa=>'Str');
has 'description'     => (is=>'rw');
has '_series'         => (is=>'rw', isa=>'GEO::Series');
has 'phenotype'       => (is=>'rw', isa=>'Str');

class_has 'prefix'    => (is=>'ro', isa=>'Str', default=>'gsd' );
class_has 'collection'=> (is=>'ro', isa=>'Str', default=>'ds_samples');
class_has 'subdir'    => (is=>'ro', isa=>'Str', default=>'sample_data');
class_has 'word_fields' => (is=>'ro', isa=>'ArrayRef', default=>sub {[qw(title description)]});


# series accessor
# fetches series from db if haven't already done so
sub series {
    my ($self)=@_;
    return $self->_series if $self->_series;
    my $series=GEO::Series->new($self->dataset_id); # calls get_mongo_record, populates object
    warnf "SeriesData::Series(%s): series is %s", $self->geo_id, Dumper($series);
    $self->_series($series);
    $series;
}



# return the full path the the data
# fixme: sometimes this ends in .table.data, sometimes in .data (arrgghh!)
sub datafile {
    my ($self)=@_;
    join('/', $self->path, join('.', $self->geo_id, 'table.data'));
}

sub path {
    my ($self)=@_;
    $self->geo_id =~ /GSM\d\d\d/ or dief "badly formed SeriesData geo_id: %s", $self->geo_id;
    my $ssubdir=$&;
    join('/',$self->data_dir, $self->subdir, $ssubdir);
}

sub report {
    my ($self)=@_;
    my $report=sprintf("%10s (%s): %s, %s", $self->geo_id, ref $self, $self->title, $self->description);
    $report.=sprintf("\n            phenotype: %s", $self->phenotype) if $self->phenotype;
    $report.=sprintf("\n            dataset: %s", $self->dataset_id) if $self->dataset_id;
    $report;
}
1;
