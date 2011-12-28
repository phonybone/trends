package GEO::word2geo;
use Moose;
extends 'GEO';
use MooseX::ClassAttribute;
use Data::Dumper;

has 'word' => (is=>'rw', isa=>'Str');
class_has 'collection'=> (is=>'ro', isa=>'Str', default=>'word2geo');
class_has 'indexes' => (is=>'rw', isa=>'ArrayRef', default=>sub { [{geo_id=>1, word=>1},{unique=>1}] });
class_has 'prefix'    => (is=>'ro', isa=>'Str', default=>'w2g' );

sub BUILD { shift; }		# just return self; overrides GEO::BUILD()


sub equals {
    my ($self, $other)=@_;
    $self->geo_id eq $other->geo_id && $self->word eq $other->word;
}

sub as_string {
    my ($self)=@_;
    sprintf("%s:%s", $self->{word}, $self->{geo_id});
}



1;

