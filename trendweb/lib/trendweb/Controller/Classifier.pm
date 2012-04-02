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



# Split an $id to extract its base and format.  If no format exists, the id is unchanged.
# return a two-element list[ref] where:
# $list[0] = the chopped $id
# $list[1] = the format (in lowercase)

sub get_format {
    my ($self, $id, $default_format)=@_;
    $default_format ||= $self->default_format;
    my @stuff=split(/\./,$id);
    my @answer;
    if (scalar @stuff == 1) {
	@answer=($id, lc $default_format);
    } else {
	my $format=pop @stuff;
	@answer=(join('.', @stuff), lc $format)
    }
    wantarray? @answer:\@answer;
}

#sub classifier_GET :Chained('/') :PathPart('classifier') :CaptureArgs(1) {
sub classifier_GET :Path :Args(1) {
    my ($self, $c, $id)=@_;

    my $format;
    ($id,$format)=$self->get_format(uri_unescape($id));

    my $query=($id =~ /^\d+$/)? {id=>$id} : {name=>uri_unescape($id)};
    my $classifier=Classifier->new(%$query);
#    $c->log->debug(sprintf("query is %s", Dumper($query)));
#    $c->log->debug(sprintf "classifier is %s", Dumper($classifier));
    if ($classifier->_id) {
	delete $classifier->{_id};
	$c->stash->{entity}=unbless $classifier;
	$c->stash->{format}=$format;
	$c->forward('View::JSON');
    } else {
	$self->status_not_found($c, message=>"no classifier for '$id'");
    }	
}

sub edit {

}


__PACKAGE__->meta->make_immutable;

1;
