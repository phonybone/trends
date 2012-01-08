package Person;
use Moose;
use MooseX::ClassAttribute;
extends 'Mongoid';

use PhonyBone::FileUtilities qw(warnf dief);

has 'name' => (is=>'rw', isa=>'Str');
has 'age'  => (is=>'rw', isa=>'Int');

class_has 'db_name'         => (is=>'ro', isa=>'Str', default=>'earth_db');	
class_has 'collection_name' => (is=>'ro', isa=>'Str', default=>'people');




1;
