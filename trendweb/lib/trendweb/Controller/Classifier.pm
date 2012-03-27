package trendweb::Controller::Classifier;
use Moose;
use MooseX::ClassAttribute;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

class_has default_format => (is=>'ro', isa=>'Str', default=>'json');

use Classifier;
use Data::Dumper;
use URI::Escape;

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched trendweb::Controller::Classifier in Classifier.');
}

# Split an $id to extract its base and format.  If no format exists, the id is unchanged.
# return a two-element list[ref] where:
# $list[0] = the chopped $id
# $list[1] = the format (in lowercase)

sub get_format {
    my ($self, $id, $default_format)=@_;
    $default_format ||= $self->default_format;
    my @stuff=split(/\./,$id);
    my @answer;
    if (scalar @stuff == 1) {
	@answer=($id, lc $default_format);
    } else {
	my $format=pop @stuff;
	@answer=(join('.', @stuff), lc $format)
    }
    wantarray? @answer:\@answer;
}

sub classifier_GET :Path('/classifier') :Args(1) {
    my ($self, $c, $id)=@_;

    my $format;
    ($id,$format)=$self->get_format(uri_unescape($id), 'html');
    my $classifier=Classifier->new($id);

    if ($classifier->_id) {
	$c->stash(entity=>$classifier);
	if ($format eq 'html') {
	    $c->stash(template=>'classifier/classifier.tt');
	    $c->forward('View::HTML');
	} elsif ($format eq 'json') {
	    $c->forward('View::JSON');
	} else {
	    $c->response->status(415); # Unsupported media type
	}
    } else {
	$self->status_not_found($c, message=>"no classifier for id '$id'");
    }
}

sub by_name :Path('/classifier/by_name') :Args(1) {
    my ($self, $c, $name)=@_;
    my $format;
    ($name,$format)=$self->get_format(uri_unescape($name), 'json');
    my $record=Classifier->mongo->find_one({name=>$name});
    $self->status_not_found($c, message=>"no classifier with name '$name'") 
	unless ref $record->{_id} eq 'MongoDB::OID';
    my $classifier=Classifier->new(%$record);

    if ($format eq 'html') {
	$c->stash(entity=>$classifier);
	$c->stash(template=>'classifier/classifier.tt');
	$c->forward('View::HTML');
    } elsif ($format eq 'json') {
	delete $record->{_id};
	$c->stash(entity=>$record);
	$c->forward('View::JSON');
    } else {
	$c->response->status(415); # Unsupported media type
    }
}


__PACKAGE__->meta->make_immutable;

1;
