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
has 'series'         => (is=>'rw', isa=>'GEO::Series', lazy=>1, builder=>'_build_series');
has 'phenotype'       => (is=>'rw', isa=>'Str');



# series accessor
# fetches series from db if haven't already done so
sub _build_series {
    my ($self)=@_;
    my $series=GEO::Series->new($self->dataset_id); # calls get_mongo_record, populates object
}



# return the full path the the data
# fixme: sometimes this ends in .table.data, sometimes in .data (arrgghh!)
sub datafile {
    my ($self)=@_;
    join('/', $self->path, join('.', $self->geo_id, 'table.data'));
}

# return the Series' data as a 1D array;
# actually returns a hashref: k=probe_id (or other gene id), v=expression value
# throws exceptions!
sub as_vector_hash {
    my ($self)=@_;
    my $vector={};
    open(DONUT, $self->datafile) or dief "Can't open %s: $!\n", $self->datafile;
    <DONUT>; <DONUT>;		# burn first two lines
    while (<DONUT>) {
	chomp;
	my (@fields)=split(',');
	$vector->{$fields[0]}=$fields[1];
    }
    $vector;
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
