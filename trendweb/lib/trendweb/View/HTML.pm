package trendweb::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
    WRAPPER => 'header.tt',
#    EVAL_PERL => 1,
);

has 'window_width' => (is=>'ro', isa=>'Int', default=>80);

use Template::Stash;
if (1) {
    Template::Stash->define_vmethod('scalar', 'ref', sub { 'SCALAR' });
    Template::Stash->define_vmethod('array', 'ref', sub { 'ARRAY' });
    Template::Stash->define_vmethod('hash', 'ref', sub { 'HASH' });
} else {
    $Template::Stash::SCALAR_OPS->{ref} = sub { 'SCALAR' };
    $Template::Stash::LIST_OPS->{ref} = sub { 'ARRAY' };
    $Template::Stash::HASH_OPS->{ref} = sub { 'HASH' };
}

# Take a search result and return a hash ref with fields needed by search_results.tt
# $sr is a search results as returned by GEO::Search->results.  
sub post_process_search_results {
    my ($self, $c, $results)=@_;

    my $search_term=$c->req->params->{search_term};
    my $window_width=$self->window_width;

    foreach my $geo_id (keys %$results) { # don't use 'each %$results'; 
	my $sources=$results->{$geo_id};
	my $result={sources=>$sources};
	my $i=0;

	# get $short_source (window around first occurence of $search_term)
	# also, add some stuff to the $source hashref:
	foreach my $source (@$sources) {
	    if (length $source->{source} > $window_width) {
		my $short_source=substr($source->{source}, 0, $window_width);
		$source->{short_source}=$short_source;
		$source->{has_short}=1;
	    } else {
		$source->{short_source}=$source->{source};
	    }

	    $source->{source_id}=join('_', $geo_id, $i);
	    $i++;
	}
	my $geo=GEO->factory($geo_id);
	$result->{geo_id}=$geo_id;
	$result->{title}=$geo->title;
	$result->{$geo_id}=$result;
#	$result->{uri}=$c->uri_for($c->controller('geo')->action_for("$geo_id/view"), $geo_id);
	$result->{uri}=$c->uri_for("/geo/$geo_id/view");
	$results->{$geo_id}=$result;
    }
    
}

1;
