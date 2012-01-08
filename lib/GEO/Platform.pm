package GEO::Platform;
use Moose;
use MooseX::ClassAttribute;
extends 'GEO';

use Carp;
use Data::Dumper;

has 'title' => (is=>'rw', isa=>'Str');
has 'geo_accession' => (is=>'rw', isa=>'Str');
has 'status' => (is=>'rw', isa=>'Str');
has 'submission_date' => (is=>'rw', isa=>'Str');
has 'last_update_date' => (is=>'rw', isa=>'Str');
has 'technology' => (is=>'rw', isa=>'Str');
has 'distribution' => (is=>'rw', isa=>'Str');
has 'organism' => (is=>'rw', isa=>'Str');
has 'taxid' => (is=>'rw', isa=>'Str');
has 'manufacturer' => (is=>'rw', isa=>'Str');
has 'manufacture_protocol' => (is=>'rw');
has 'description' => (is=>'rw'); # list
has 'web_link' => (is=>'rw');
has 'contact_name' => (is=>'rw', isa=>'Str');
has 'contact_email' => (is=>'rw', isa=>'Str');
has 'contact_phone' => (is=>'rw', isa=>'Str');
has 'contact_institute' => (is=>'rw', isa=>'Str');
has 'contact_address' => (is=>'rw', isa=>'Str');
has 'contact_city' => (is=>'rw', isa=>'Str');
has 'contact_state' => (is=>'rw', isa=>'Str');
has 'contact_zip/postal_code' => (is=>'rw', isa=>'Str');
has 'contact_country' => (is=>'rw', isa=>'Str');
has 'contact_web_link' => (is=>'rw', isa=>'Str');
has 'relation' => (is=>'rw', isa=>'ArrayRef');
has 'data_row_count' => (is=>'rw', isa=>'Str');


class_has 'prefix'          => (is=>'ro', isa=>'Str', default=>'GPL' );
class_has 'collection_name' => (is=>'ro', isa=>'Str', default=>'platform');
class_has 'subdir'          => (is=>'ro', isa=>'Str', default=>'platforms');



sub path {
    my ($self)=@_;
    return join('/', $self->data_dir, $self->subdir, $self->geo_id);
}




1;
