package Probe2Sym;
use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose;
use File::Basename;
use File::Spec::Functions;
use Cwd qw(abs_path);
use PhonyBone::FileUtilities qw(spitString);
use Data::Babel::Client;

has 'p2s' => (is=>'ro', isa=>'HashRef', lazy=>1, builder=>'_build_p2s');
has 'cache_dir' => (is=>'ro', isa=>'Str', default=>dirname(__FILE__));
has 'cache_file' => (is=>'ro', isa=>'Str', default=>'probe2sym.pl');
has 'cache_path' => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_build_cache_path');

sub _build_cache_path { 
    my $self=shift;
    catfile($self->cache_dir, $self->cache_file)
}

sub _build_p2s {
    my ($self)=@_;

    if (-r $self->cache_path) {
	my $probe2sym=do $self->cache_path;
	return $probe2sym;
    }

    STDERR->autoflush(1);
    print STDERR "fetching probe_id -> gene symbols...";
    my $babel_client=new Data::Babel::Client;
    my $table=$babel_client->translate(input_type=>'probe_affy', 
				       output_types=>['gene_symbol'],
				       input_ids_all=>1, 
				       output_format=>'json');
    printf STDERR "got %d translations\n", scalar @$table;

    my %probe2sym=map {($_->[0], $_->[1])} @$table;

    # cache results:
    if (my $cache_path=$self->cache_path) {
#	eval {
	    spitString(Dumper(\%probe2sym), $cache_path);
#	};			# ignore errors
	warn $@ if $@ && $ENV{DEBUG};
    }

    \%probe2sym;
}



sub as_sym {
    my ($self, $probe_id)=@_;
    $self->p2s->{$probe_id};
}


__PACKAGE__->meta->make_immutable;

1;
