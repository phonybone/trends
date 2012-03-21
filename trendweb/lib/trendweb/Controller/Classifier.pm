package trendweb::Controller::Classifier;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

use Classifier;
use Data::Dumper;
use URI::Escape;

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched trendweb::Controller::Classifier in Classifier.');
}


sub classifier_GET :Path('/classifier') :Args(1) {
    my ($self, $c, $id)=@_;
    $id=uri_unescape($id);
    my $classifier=Classifier->new(name=>$id);
    if ($classifier->_id) {
	$c->stash(entity=>$classifier, template=>'classifier/classifier.tt');
	$c->forward('View::HTML');
    } else {
	$self->status_not_found($c, message=>"no classifier for id '$id'");
    }
}



=head1 NAME

trendweb::Controller::Classifier - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index
 =cut




=head1 AUTHOR

Victor Cassen,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
