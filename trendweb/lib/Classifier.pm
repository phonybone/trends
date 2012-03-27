package Classifier;
use Carp;
use Data::Dumper;

use Moose;
extends 'Mongoid';
use MooseX::ClassAttribute;

has name=>(is=>'rw', isa=>'Str'); # primary key

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
    my $pk=$self->primary_key;

    if ($self->$pk && !$self->_id) {
	my $id=$self->$pk;
	my $record=$self->mongo->find_one({$pk=>$id});
	$self->hash_assign(%$record) if $record;
    }
    $self;
}

sub _class_init {
    my ($class)=@_;
    $class->mongo->slave_okay(1);
}

__PACKAGE__->_class_init;

1;
