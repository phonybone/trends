package trendweb;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory


use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple
    StackTrace
/;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application (defaults, override in trendweb.conf)

__PACKAGE__->config(
    name => 'trendweb',
    'View::JSON'=>{expose_stash => [qw(entity)]},
    'View::HTML'=>{expose_stash => [qw(entity)]},

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
);

sub add_to_page {
    my ($self, $src, $where)=@_;
    my $target=$self->path_to(File::Spec->splitdir($src));
#    -r $target or die "'$target': no such file";
    push @{$self->stash->{page}->{$where}}, $src;
}

sub add_js_script {
    my ($self, $src)=@_;
    $self->add_to_page($src, 'scripts');
}

sub add_css {
    my ($self, $src)=@_;
    $self->add_to_page($src, 'css_srcs');
}

sub title {
    my ($self, $title)=@_;
    $self->stash->{page}->{title}=$title if $title;
    $self->stash->{page}->{title};
}

sub push_stack {
    my ($self, $caller, $msg)=@_;
    my $action_name=$self->stack->[-1]->name;
    my $action=$self->controller->action_for($action_name);
    my $uri=$action? $self->uri_for($action) : undef;
    push @{$self->stash->{matches}}, {ref($caller) => {$action=>$uri, msg=>$msg}};
}

# Start the application
__PACKAGE__->setup();




















=head1 NAME

trendweb - Catalyst based application

=head1 SYNOPSIS

    script/trendweb_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<trendweb::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
