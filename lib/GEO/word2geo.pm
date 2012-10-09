package GEO::word2geo;
use Moose;
use MooseX::ClassAttribute;
use Data::Dumper;

has 'geo_id' => (is=>'rw', isa=>'Str');
has 'word' => (is=>'rw', isa=>'Str');
has 'source' => (is=>'rw', isa=>'Str');

class_has 'db_name'         => (is=>'ro', isa=>'Str', default=>'geo');
class_has 'collection_name' => (is=>'ro', isa=>'Str', default=>'word2geo');
class_has 'indexes' => (is=>'rw', isa=>'ArrayRef', default=>sub { [ {
    keys=>[qw(geo_id word)], opts=>{unique=>1},
								    } ] } );
with 'Mongoid';


# compare geo_id and word fields for equality:
sub equals {
    my ($self, $other)=@_;
    $self->geo_id eq $other->geo_id && $self->word eq $other->word;
}

sub as_string {
    my ($self)=@_;
    sprintf("%s:%s", $self->{word}, $self->{geo_id});
}

# class method:
sub histo {
    my ($class)=@_;
    my %histo;
    
    my $cursor=$class->mongo->find;
    while ($cursor->has_next) {
	my $record=$cursor->next;
	my $geo_id=$record->{geo_id} or confess "no geo_id";
	my $word=$record->{word} or confess "no word";
	push @{$histo{$word}}, $geo_id;
    }

    wantarray? %histo:\%histo;
}

1;

