package GEO::Sample;
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

has 'dataset_ids'     => (is=>'rw');
has 'title'           => (is=>'rw', isa=>'Str');
has 'description'     => (is=>'rw'); # comes from Dataset .soft files (table headings)
has 'phenotype'       => (is=>'rw', isa=>'Str');
has 'path_raw_data' => (is=>'rw', isa=>'Str');

has 'series_ids'    => (is=>'rw', isa=>'ArrayRef', default=>sub{[]});
has 'dataset_ids'   => (is=>'rw', isa=>'ArrayRef', default=>sub{[]});
has 'subset_ids'    => (is=>'rw', isa=>'ArrayRef', default=>sub{[]});



class_has 'prefix'    => (is=>'ro', isa=>'Str', default=>'gsm' );
class_has 'collection_name'=> (is=>'ro', isa=>'Str', default=>'samples');
class_has 'subdir'    => (is=>'ro', isa=>'Str', default=>'sample_data');
class_has 'word_fields' => (is=>'ro', isa=>'ArrayRef', default=>sub {[qw(title description)]});


# series accessor
# fetches series from db if haven't already done so
# returns an array[ref] of series objects, or undef if none
has '_series'         => (is=>'rw', isa=>'GEO::Series');
sub series {
    my ($self)=@_;
    return $self->_series if $self->_series;
    my $geo_id=$self->geo_id;
    my $series_ids=$self->series_ids or return undef;
    confess "$geo_id: '$series_ids': should be an arrayref" unless ref $series_ids eq 'ARRAY';
    my @series=map {GEO::Series->new($_)} @$series_ids;
    $self->_series(\@series);
    wantarray? @series:\@series;
}



# return the full path the the data
# fixme: sometimes this ends in .table.data, sometimes in .data (arrgghh!)
sub data_file {
    my ($self)=@_;
    join('/', $self->path, join('.', $self->geo_id, 'data'));
}

# table.data files 
sub table_data_file {
    my ($self)=@_;
    join('/', $self->path, join('.', $self->geo_id, 'table.data'));
}

# returns sample's data as a hashref: k=probe_id (or other gene id), v=expression value
# throws exceptions if can't find $self->data_file
sub as_vector_hash {
    my ($self, $opts)=@_;
    $opts||={};
    my $vector={};
    my $data_src=$opts->{data_src} eq 'genes' ? $self->data_file : $self->table_data_file;
    open(DONUT, $data_src) or dief "Can't open %s: $!\n", $data_src;
    <DONUT>; <DONUT>;		# burn first two lines
    while (<DONUT>) {
	chomp;
	my (@fields)=split(',');
	$vector->{$fields[0]}=$fields[1];
    }
    $vector;
}

# path to directory containing sample data
sub path {
    my ($self)=@_;
    $self->geo_id =~ /GSM\d\d?\d?/ or dief "badly formed Sample geo_id: %s", $self->geo_id;
    my $ssubdir=$&;
    join('/',$self->data_dir, $self->subdir, $ssubdir);
}

# compile all the descriptions related to this sample (eg from subsets, etc)
sub descriptions {
    my ($self)=@_;
    my %descs;
    $descs{$self->geo_id}=join(', ', @{$self->description}) if $self->description; # get our own first
    foreach my $geo_id (@{$self->series_ids}, @{$self->subset_ids}, @{$self->dataset_ids}) {
	my $geo=GEO->factory($geo_id);
	$descs{$geo_id}=$geo->{description} if $geo->{description};
    }
    wantarray? %descs : join("\n", map {sprintf("%10s: %s", $_, $descs{$_})} sort keys %descs);
}

sub report {
    my ($self)=@_;
    my $report=sprintf("%10s (%s): %s, %s", $self->geo_id, ref $self, ($self->title || '<no title>'), ($self->description || '<no description>'));
    $report.=sprintf("\n            phenotype: %s", $self->phenotype) if $self->phenotype;

    foreach my $pair (['series', $self->series_ids], 
		      ['datasets', $self->dataset_ids],
		      ['subsets', $self->subset_ids]) {
	my ($name, $list)=@$pair;
	my $str=ref $list? join(', ', @$list) : $list;
	$report.=sprintf("\n            %s: %s", $name, $str);
    }

    $report;
}


1;
