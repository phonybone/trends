package trendweb::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use Carp;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}


sub default :Path {
    my ( $self, $c ) = @_;
    
    $c->response->body( 'Page not found' . '<pre> req path=' . $c->req->path . '</pre>');
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {
    my ($self, $c)=@_;
#    confess "We're not supposed to get here";
#    $c->res->body("<pre>\n" . Dumper($c->stash->{matches}) . "</pre>");
}


__PACKAGE__->meta->make_immutable;

1;


__END__

=head1 NAME

trendweb::Controller::Root - Root Controller for trendweb

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut


=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
