package trendweb::Controller::GEO;
use Moose;
use Data::Dumper;
use namespace::autoclean;
use Data::Structure::Util qw(unbless);
use lib '/mnt/price1/vcassen/trends/lib';
use GEO;			# shouldn't we, like, be getting the model from the stash or something?
use JSON;

use Data::Dumper;

BEGIN {extends 'Catalyst::Controller::REST'; }

# sub index :Path :Args(0) {
#     my ( $self, $c ) = @_;
#     $c->response->body('Matched trendweb::Controller::GEO in GEO.');
# }


# base of the chain: retrieves the geo object in question, stores to the stash:
sub base : Chained('/') PathPart('geo') CaptureArgs(1) {
    my ($self, $c, $geo_id)=@_;
    my $geo=eval {GEO->factory($geo_id)};
    if ($@ || ref $geo->_id ne 'MongoDB::OID') {
	$self->status_not_found($c, message=>"No geo object for $geo_id ($@)");
	$c->detach;
    }
    $c->stash->{geo}=$geo;
}


########################################################################
## REST methods
########################################################################

sub geo : Chained('base') PathPart('') Args(0) ActionClass('REST') {}

sub geo_GET {
    my ($self, $c)=@_;
    my $geo=$c->stash->{geo};
    delete $geo->{_id};
#    $c->log->debug('geo_GET: want to encode '.$geo->geo_id);
    $geo->samples if $geo->can('samples');		# trigger lazy methods
    $geo->subsets if $geo->can('subsets');
    $c->stash->{rest}=unbless($geo);

    # we don't set $c->stash->{entity} and $c->forward('View::JSON')
    # because for 'application/json', ActionClass('REST') does that for us.
    # But for 'text/html' (ie, generic browser request), we still get 
    # readable output from View::HTML.
}

sub geo_POST {
    my ($self, $c)=@_;
    my $geo_data=$c->req->data or
	return $self->status_bad_request($c, message=>"No data supplied");

    my $geo=$c->stash->{geo} or die "wtf? no stash->geo";
    unless ($geo_data->{geo_id} eq $geo->geo_id) {
	return $self->status_bad_request($c, message=>sprintf("geo_ids don't match: '%s' vs %s", 
						       $geo_data->{geo_id}, 
						       $geo->geo_id));
    }


    # build a new geo object from the POST data and save it:
    my $geo_class=GEO->class_of($geo);
    my $new_geo=$geo_class->new(%$geo_data);
    $new_geo->save;

    # store to stash:
    $new_geo=unbless($new_geo);
    delete $new_geo->{_id};
    $self->status_ok($c, entity=>$new_geo);
}

########################################################################
# GUI methods
########################################################################

# fixme: this might get changed to edit_dataset.  It currently is 
# WAY too dataset-specific.
sub view : Chained('base') PathPart('view') Args(0) {
    my ($self,$c)=@_;
    my $geo=$c->stash->{geo};

    my $class=lc GEO->class_of($geo);
    $class=~s/.*:://;

    $c->stash(template=>"$class/view.tt", entity=>$geo, $class=>$geo);
    $c->title($geo->geo_id);
    $c->add_js_script('/jquery-1.7.1.js');
    $c->add_css('/dataset_editor.css'); # fixme: too specific
    $c->add_js_script("/js/${class}_editor.js"); # fixme: not defined for $class != 'dataset'
    $c->forward('View::HTML');
}

########################################################################
# Named paths
########################################################################

sub bulk : Path('bulk') ActionClass('REST') {}
sub bulk_POST {
    my ($self, $c)=@_;
    my $geo_data=$c->req->data or
	return $self->status_bad_request($c, message=>"No data supplied");
    return $self->status_bad_request($c, message=>"Bad data: not a list of records") 
	unless ref $geo_data eq 'ARRAY';

    my @errors;
    foreach my $record (@$geo_data) {
	eval {
	    my $geo_id=$record->{geo_id} or die "no geo_id";
	    my $geo=GEO->factory($geo_id); # get the old record, or a blank if new: don't use GEO->from_data, because then we'll *always* get a new record
	    delete $record->{_id}; # shouldn't be there anyway
	    $geo->hash_assign(%$record);
	    $geo->save;
	};
	push @errors, $@ if $@;
    }
    if (@errors) {
	return $self->status_bad_request($c, message=>join("\n", @errors));
    } else {
	return $self->status_ok($c, entity=>$geo_data);
    }
}


# We may want to move this to a different controller...
sub search : Path('search') ActionClass('REST')  {}
sub search_POST {
    my ($self, $c)=@_;
    $c->log->debug(sprintf "Arrived at search: args are <pre>%s</pre>", Dumper($c->req->params));
    my $search_term=$c->req->params->{search_term} or
	return $self->status_bad_request($c, message=>'missing search term');
    my $search=$c->model('Search')->new($search_term);

    my $results=$search->results; # format? should be a structure containing all relevelent info



    return $self->status_ok($c, entity=>\$results);
}

__PACKAGE__->meta->make_immutable;

1;
