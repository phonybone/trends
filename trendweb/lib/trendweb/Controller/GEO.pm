package trendweb::Controller::GEO;
use Moose;
use namespace::autoclean;
use Data::Dumper;

use lib '/mnt/price1/vcassen/trends/lib';
use GEO;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->response->body('Matched trendweb::Controller::GEO in GEO.');
}

=head2
    geo()

    Returns a geo object.
    Uses suffix of uri to determine return format.  Allowable suffixes
    are '', '.html', or '.json'.  An empty suffix results in HTML.

=cut

sub geo :Path('/geo') :Args(1) {
    my ( $self, $c, $geo_id) = @_;
    my $format='html';

    if ($geo_id=~/^(G\w\w[_\d]+)(\.(\w+))?$/i) {
	$geo_id=$1;
	$format = lc $3 || $format;
    } else {
	$c->error("bad geo_id: '$geo_id'");
    }

    my $geo=GEO->factory($geo_id);
    $geo->{fart}={this=>'that', these=>'those',
		  list=>[qw(a b c d e)],
		  hash=>{more=>'junk', totally=>'boring'}};

    if ($format eq 'html') {
	$c->stash(geo=>$geo);
	$c->forward('View::HTML');
    } elsif ($format eq 'json') {
	$c->stash(geo=>$geo->json);
	$c->forward('View::JSON');
    } else {
       $c->error("unknown format: '$format'");
    }
}

__PACKAGE__->meta->make_immutable;

1;
