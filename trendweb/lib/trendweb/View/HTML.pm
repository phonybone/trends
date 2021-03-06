package trendweb::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
    WRAPPER => 'header.tt',
#    EVAL_PERL => 1,
);


use Template::Stash;
if (1) {
    Template::Stash->define_vmethod('scalar', 'ref', sub { 'SCALAR' });
    Template::Stash->define_vmethod('array', 'ref', sub { 'ARRAY' });
    Template::Stash->define_vmethod('hash', 'ref', sub { 'HASH' });
} else {
    $Template::Stash::SCALAR_OPS->{ref} = sub { 'SCALAR' };
    $Template::Stash::LIST_OPS->{ref} = sub { 'ARRAY' };
    $Template::Stash::HASH_OPS->{ref} = sub { 'HASH' };
}

=head1 NAME

trendweb::View::HTML - TT View for trendweb

=head1 DESCRIPTION

TT View for trendweb.

=head1 SEE ALSO

L<trendweb>

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
