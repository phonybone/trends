package GEO::Sample;
use Moose;
use MooseX::ClassAttribute;

use Data::Dumper;
use File::Spec;
use PhonyBone::FileUtilities qw(warnf dief);
use PhonyBone::FileIterator;

#
# Class to model series data 
#
# Problems: geo_ids conflict in format (/GSM\d+/); don't know if actual
# values overlap or not.
#

has 'title'           => (is=>'rw', isa=>'Str');
has 'description'     => (is=>'rw'); # comes from Dataset .soft files (table headings)
has 'phenotypes'       => (is=>'rw', isa=>'ArrayRef[Str]', default=>sub{[]});
has 'path_raw_data' => (is=>'rw', isa=>'Str');

has 'exp_data'      => (is=>'ro', isa=>'HashRef', lazy=>1, builder=>'_build_exp_data');

has 'series_ids'    => (is=>'rw', isa=>'ArrayRef', default=>sub{[]});
has 'series'        => (is=>'ro', isa=>'ArrayRef[GEO::Series]', lazy=>1, builder=>'_build_series');
has 'dataset_ids'   => (is=>'rw', isa=>'ArrayRef', default=>sub{[]});
has 'datasets'      => (is=>'ro', isa=>'ArrayRef[GEO::Dataset]', lazy=>1, builder=>'_build_datasets');
has 'subset_ids'    => (is=>'rw', isa=>'ArrayRef', default=>sub{[]});
has 'subsets'       => (is=>'ro', isa=>'ArrayRef[GEO::DatasetSubset]', lazy=>1, builder=>'_build_subsets');


sub _build_series {
    my ($self)=@_;
    [map { GEO->factory($_) } @{$self->series_ids}];
}

sub _build_datasets {
    my ($self)=@_;
    [map { GEO->factory($_) } @{$self->dataset_ids}];
}

sub _build_subsets {
    my ($self)=@_;
    [map { GEO->factory($_) } @{$self->subset_ids}];
}


class_has 'prefix'    => (is=>'ro', isa=>'Str', default=>'gsm' );
class_has 'collection_name'=> (is=>'ro', isa=>'Str', default=>'samples');
class_has 'subdir'    => (is=>'ro', isa=>'Str', default=>'sample_data');
class_has 'word_fields' => (is=>'ro', isa=>'ArrayRef', default=>sub {[qw(title description)]});
extends 'GEO';





# return the full path the the data (gene or probe)
sub _file {
    my ($self, $type)=@_;
    $type||='probe';
    my $suffix={gene=>'data', probe=>'table.data'}->{$type} or
	die "unknown type: '$type'";
    join('/', $self->path, join('.', $self->geo_id, $suffix));
}
sub data_file { shift->_file('gene') }
sub table_data_file { shift->_file('probe') }

# returns sample's data as a hashref: k=probe_id (or other gene id), v=expression value
# throws exceptions if can't find $self->data_file
sub as_vector_hash {
    my ($self, $opts)=@_;
    $opts||={id_type=>'probe'};
    my $vector={};
    my $data_src=$self->_file($opts->{id_type});

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
    my @lines;

    push @lines, sprintf("%10s (%s): %s, %s", $self->geo_id, ref $self, ($self->title || '<no title>'), ($self->description || '<no description>'));
    push @lines, sprintf("            phenotypes: %s", join(', ',@{$self->phenotypes})) if $self->phenotypes;

    foreach my $pair (['series', $self->series_ids], 
		      ['datasets', $self->dataset_ids],
		      ['subsets', $self->subset_ids]) {
	my ($name, $id_list)=@$pair;
	$id_list=[$id_list] unless ref $id_list;

	foreach my $id (@$id_list) {
	    my $geo=GEO->factory($id);
	    my $line=sprintf("            %8s: %12s %s", $name, $id, $geo->title);
	    push @lines, $line;
	}
    }

    join("\n", @lines);
}

# Currently this only uses normalized GDS data
# returns a hashref: k=gene symbol, v=exp value
sub _build_exp_data {
    my ($self)=@_;
    my $exp_data={};
    my $fi=new PhonyBone::FileIterator($self->data_file);
    while (my $line=$fi->next) {
	my ($gene, $exp)=split(/\s+/, $line);
	$exp_data->{$gene}=$exp eq 'null'? 0.0 : +$exp;
    }    
    $exp_data;
}

1;
