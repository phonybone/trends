package trendweb::Controller::ClassifierEditor;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

# This is a web service that dispenses HTML forms for editing (and searching?)
# Classifier objects.

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched trendweb::Controller::ClassifierEditor in ClassifierEditor.');
}

# Return a form filled out with information about a given classifier:

sub edit_classifier :Global :Args(1) {
    my ($self, $c, $id)=@_;
    my $classifier=Classifier->new($id);
}


__PACKAGE__->meta->make_immutable;

1;
