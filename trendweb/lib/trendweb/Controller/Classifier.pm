package trendweb::Controller::Classifier;
use Moose;
use MooseX::ClassAttribute;


use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }

class_has default_format => (is=>'ro', isa=>'Str', default=>'json');

use Classifier;
use Data::Dumper;
use URI::Escape;
use Data::Structure::Util qw(unbless);

sub index :Path('/') :Args(0) {
    my ($self, $c)=@_;
}

# Split an $id to extract its base and format.  If no format exists, the id is unchanged.
# return a two-element list[ref] where:
# $list[0] = the chopped $id
# $list[1] = the format (in lowercase)


# return list[ref]: ($id, $format, $query)
sub parse_id {
    my ($self, $id, $default_format)=@_;
    $default_format ||= $self->default_format;

    my @stuff=split(/\./,uri_unescape($id));
    push @stuff, $default_format if @stuff==1;
    my $format=lc pop @stuff;
    $id=join('.', @stuff);

    my $query;
    if ($id=~/^\d+$/) {
	$id=int($id);
	$query={id=>$id};
    } else {
	$query={name=>uri_unescape($id)};
    }

    my @answer=($id, $format, $query);
    wantarray? @answer:\@answer;
}

sub classifier : Path('/classifier') :Args(1) :ActionClass('REST') {
    my ($self, $c, $id)=@_;

    my ($format, $query);      
    ($id, $format, $query)=$self->parse_id($id);
    $c->stash->{classifier_id}=$id;

#    $c->log->debug(sprintf "looking for classifier: %s", Dumper($query));
    my $classifier=Classifier->new(%$query);
#    $c->log->debug(sprintf "classifier: query is %s\nclassifier: classifier is %s", Dumper($query), Dumper($classifier));
    if ($classifier->_id) {
	$c->stash->{classifier}=$classifier;
	$c->stash->{format}=$format;
    }
}

#sub classifier_GET :Chained('/') :PathPart('classifier') :CaptureArgs(1) {
sub classifier_GET {
    my ($self, $c)=@_;

    if (my $classifier=$c->stash->{classifier}) {
	$self->status_ok($c, entity=>unbless $classifier);
	$c->forward('View::JSON');
    } else {
	$self->status_not_found($c, message=>sprintf "no classifier for '%s'", $c->stash->{classifier_id});
    }	
}

# Use this for either new or existing classifiers (PUT/POST semantics suck)
sub classifier_POST {
    my ($self, $c)=@_;

    my $classifier=$c->stash->{'classifier'};
    unless (defined $classifier) {
	return $self->status_not_found($c, message=>sprintf "no classifier for '%s'", $c->stash->{classifier_id});
    }

    my $req=$c->req;
    return $self->status_bad_request($c, 'no request???') unless $req;
#    $c->log->debug(sprintf "POST: req is %s", Dumper($req));

    my $data=$c->req->body_parameters;
    unless (defined $data) {
	return $self->status_bad_request($c,
					 message=>'No classifier data');
    }
#    $c->log->debug(sprintf "POST: data is %s", Dumper($data));

    if ($data->{id} != $classifier->id) {
	return $self->status_bad_request($c,
					 message=>sprintf 'id mismatch: %s vs %s', $data->{id}, $classifier->id);
    }

    $classifier->hash_assign(%$data);
    my $ret=Classifier->mongo->save($classifier); # does insert or upsert
#    $c->log->debug(sprintf "POST: classifier is now ", Dumper($classifier));

    # stupid hack to remove .html or similar from location
    my $location=lc $c->req->uri;
    my @s1=split('/', $location);
    my $s2=pop @s1;
    my @s2=split('\.', $s2);
    pop @s2 unless @s2<=1;
    $location=join('/', @s1, join('.',@s2));

    $self->status_created($c, location=>$location, entity=>unbless $classifier);
#    $c->forward('View::JSON'); # replace with status_found or something?
}


__PACKAGE__->meta->make_immutable;

1;
