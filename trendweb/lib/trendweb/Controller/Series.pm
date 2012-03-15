package trendweb::Controller::Series;
use Moose;
use namespace::autoclean;

#use lib "$ENV{TRENDS_HOME}/lib";
use lib '/mnt/price1/vcassen/trends/lib';
use GEO::Series;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

trendweb::Controller::Series - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched trendweb::Controller::Series in Series.');
}

=head2 series

=cut

sub series :Path('/series') :Args(1) {
    my ( $self, $c, $gse) = @_;

    my $format='html';
    if ($gse =~ /^(GSE\d+)\.json$/i) {
	$gse=$1;
	$format='json';
    } elsif ($gse=~/^(GSE\d+)\.html$/i) {
	$gse=$1;
    }

    my $series=new GEO::Series($gse);
    $c->stash(timestamp => scalar localtime());
    if ($format eq 'html') {
	$c->stash(series=>$series);
	$c->forward('View::HTML');
    } elsif ($format eq 'json') {
	$c->stash(series=>$series->json);
	$c->forward('View::JSON');
    }
}


=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
