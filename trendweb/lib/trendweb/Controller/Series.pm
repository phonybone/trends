package trendweb::Controller::Series;
use Moose;
use namespace::autoclean;

#use lib "$ENV{TRENDS_HOME}/lib";
use lib '/mnt/price1/vcassen/trends/lib';
use GEO::Series;
use Data::Dumper;

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
    my ( $self, $c, $gse ) = @_;

    my $series=new GEO::Series($gse);
    my $dump=$series->dump();    
    my $ts=scalar localtime();
    my $msg=sprintf("dump (%d) (%s) is %s", length($dump), $ts, $dump);
    $c->log->debug($msg);
    $c->response->body($msg);
#    $c->response->body(sprintf("<pre>%s</pre>", $series->report(full=>1)));
}

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
