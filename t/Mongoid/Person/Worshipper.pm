package Person::Worshipper;
use Moose;
extends 'Person';

has 'god' => (is=>'rw', isa=>'Str');
has 
