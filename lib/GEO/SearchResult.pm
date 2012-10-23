package GEO::SearchResult;
use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose;

#has 'uri' => (is=>'ro', isa=>'Str', required=>1);
has 'geo_id' => (is=>'ro', isa=>'Str', required=>1);
has 'source' => (is=>'ro', isa=>'Str', required=>1);


__PACKAGE__->meta->make_immutable;

1;
