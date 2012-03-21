package trendweb::Controller::GEO;
use Moose;
use namespace::autoclean;

use lib '/mnt/price1/vcassen/trends/lib';
use GEO;

use PhonyBone::HashUtilities qw(walk_hash);
use Data::Dumper;

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

    if ($format eq 'html') {
	$c->stash(geo=>$geo);
	$c->forward('View::HTML');
    } elsif ($format eq 'json') {
	my $host='localhost:3000';
	my $suffix='json';
	
	# This anonymous sub wraps (in place) a geo_id into a uri locating the geo object on our server:
	my $subrefs={str=>sub { my ($c,$i,$v)=@_; # container, index, value
				if (GEO->class_of($v)) { # shorthand for is_geo_id($v)
				    my $uri=GEO->uri_for($v, $host, $suffix);
				    my $link="<a href='$uri'>$v</a>";
				    ref $c eq 'ARRAY'? $c->[$i]=$link : $c->{$i}=$link;
				}},
	};
	my $r=$geo->record;
	delete $r->{_id};	# No objects allowed by JSON w/o special settings
	walk_hash($r, $subrefs);
	$c->stash(entity=>$r);
	$c->forward('View::JSON');
    } else {
       $c->error("unknown format: '$format'");
    }
}

__PACKAGE__->meta->make_immutable;

1;
