package Classifier;
use Carp;
use Data::Dumper;

use Moose;
extends 'Mongoid';
use MooseX::ClassAttribute;

has id  =>(is=>'rw', isa=>'Int'); # primary key
has name=>(is=>'rw', isa=>'Str'); 


class_has db_name         => (is=>'ro', isa=>'Str', default=>'geo');
class_has collection_name => (is=>'ro', isa=>'Str', default=>'classifier');
class_has primary_key     => (is=>'ro', isa=>'Str', default=>'name');

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	return $class->$orig( id => $_[0] );
    } else {
	return $class->$orig(@_);
    }
};

sub BUILD { 
    my $self=shift;
    my @args=@_;

    if ($self->id && !$self->_id) {
	my $record=$self->mongo->find_one({id=>int($self->id)});
	$self->hash_assign(%$record) if $record;
    } elsif (scalar @args > 0) {
	my @records=$self->mongo->find(@args)->all;
	my $n_args=scalar @records;
	if ($n_args==1) {
	    $self->hash_assign(%{$records[0]});
	} elsif ($n_args==0) {
	    die sprintf("no classifier for %s",Dumper(\@args));
	} else {
	    die sprintf("%d classifiers for %s",Dumper(\@args));
	}
    }

    $self;
}

1;
