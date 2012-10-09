package trendweb::Controller::RESTYCrud;
use Moose;
use namespace::autoclean;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller::REST'; }

## start of our Chained actions
sub base : Chained('/') PathPart('entry') CaptureArgs(0) {} 

## initial URL pathpart, grabs all posts
sub index : Chained('base') PathPart('') Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
    my $data = $c->req->data || $c->req->params;
    $c->push_stack($self);    
} 

## as you know, C::C::REST needs an HTTP method defined for each action you want serialized through it.
## this doesn't do much more than grab the posts that are pre-serialized (in the perl data structure sense) and serialize
## them to our desired format (XML, JSON, etc.)
sub index_GET {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## simple create action, you decide how you want to present the input UI to the user
sub create : Chained('base') PathPart('entry/new') ActionClass('REST') Args(0) {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## display the aforementioned form
sub create_GET {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## so, our first bit of CRUD. (the "C" in CRUD)
## All we need to do here is let jQgrid know what action is being performed
## (it checks this by seeing what the parameter "oper" says
## and then actually insert the record, and return some JSON for jQgrid.
sub create_POST {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## view post logic (the "R" in CRUD)
## this should be whatever you need as far as retrieval logic goes.
## this retrieves ONE entry, with a nice RESTful URI such as:
## /entry/1
## this is not an endpoint for Chained, thus it simply sets things up for us.
sub get_post : Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $postid ) = @_;
    $c->push_stack($self);    
}

## "get" endpoint
sub view_post : Chained('get_post') PathPart('') Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## REST endpoint
sub view_post_GET {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## the "D" in CRUD, set up an end point for this
sub delete_post : Chained('get_post') PathPart('delete') Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## delete a record.  Again, this is up to you to write.
sub delete_post_POST {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

## the "U" in CRUD
## sorry, D and U got reversed in definition order, but I think you'll cope :-)
sub edit_post : Chained('get_post') PathPart('update') Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}

sub edit_post_PUT {
    my ( $self, $c ) = @_;
    $c->push_stack($self);    
}


__PACKAGE__->meta->make_immutable;

1;

