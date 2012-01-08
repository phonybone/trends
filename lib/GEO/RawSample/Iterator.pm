package GEO::RawSample::Iterator;

use Moose;
use DirHandle;
use Carp;

has 'dir'        => (is=>'ro', isa=>'Str', required=>1);
has '_dirhandle' => (is=>'rw', isa=>'DirHandle');

sub BUILD {
    my ($self)=@_;
    $self->_dirhandle(new DirHandle($self->dir)) or confess sprintf("Unable to create DirHandle for %s: $!", $self->dir);
}

sub next {
    my ($self)=@_;
    while (my $n=$self->_dirhandle->read) {
	return $n if $n=~/GSM\d+/;
    }
    undef;
}

1;
