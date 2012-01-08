package Phenotype;
use Moose;
use MooseX::ClassAttribute;
extends 'Mongoid';

has 'full_name' => (is=>'rw', isa=>'Str');
has 'code'      => (is=>'rw', isa=>'Str');

class_has 'db_name'         => (is=>'rw', isa=>'Str', default=>'geo');	
class_has 'collection_name'=> (is=>'ro', isa=>'Str', default=>'pheno_wherehouse');



1;
