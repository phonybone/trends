package Soft2CSV;
use Moose;

# Use ParseSoft to convert a .soft file into a .csv file (suitable for 
# feeding to AUREA).
# 
# my $


use Carp;
use Data::Dumper;
use namespace::autoclean;
use ParseSoft;
use PhonyBone::FileUtilities qw(warnf dief);
use Data::Babel::Client;
use English;
use IO::Handle;

has 'in_filename' => (is=>'ro', isa=>'Str', required=>1);
has 'parser' => (is=>'ro', isa=>'ParseSoft', lazy=>1, builder=>'_build_parser');
sub _build_parser { 
    my $parser=new ParseSoft(filename=>shift->in_filename); 
    my $records=$parser->parse;
    $parser;
}

has 'out_directory' => (is=>'ro', isa=>'Str', default=>'.');
has 'out_filename' => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_get_out_filename');
sub _get_out_filename {
    my ($self)=@_;
    my $filename=$self->in_filename;
    $filename =~ s/\.[^.]+$/.csv/;
    if (my $out_dir=$self->out_directory) {
	$filename=~s|.*/||;
	$filename=join('/', $out_dir, $filename);
    }
    $filename;
}

has 'out_fh' => (is=>'ro', isa=>'FileHandle', lazy=>1, builder=>'_build_out_fh');
sub _build_out_fh {
    my ($self)=@_;
    my $filename=$self->out_filename;
    my $fh=new FileHandle($filename, "w") or die "Can't open $filename for writing: $!";
}

# probe2sym: use Babel to build a translation table:
has 'probe2sym' => (is=>'ro', isa=>'HashRef', lazy=>1, builder=>'_get_probe2sym');
sub _get_probe2sym {
    my ($self)=@_;
    STDERR->autoflush(1);
    print STDERR "fetching probe_id -> gene symbols...";
    my $babel_client=new Data::Babel::Client;
    my $table=$babel_client->translate(input_type=>'probe_affy', output_types=>['gene_symbol'],
					    input_ids_all=>1, output_format=>'json');
    printf STDERR "got %d translations\n", scalar @$table;

    my %probe2sym=map {($_->[0], $_->[1])} @$table;
    \%probe2sym;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	return $class->$orig( in_filename => $_[0] );
    } else {
	return $class->$orig(@_);
    }
};


sub write {
    my ($self)=@_;

    dief "%s: $!\n", $self->in_filename unless -r $self->in_filename;

    my $fh=$self->out_fh;	# put this here so it can die early
    my $probe2sym=$self->probe2sym;

    # Parse the .soft file and build %data (2D hash); $data{$probe_id}->{$sample_id}=$exp;
    my @headers=('ID_REF', 'IDENTIFIER');
    my %data;			# k=gene id, v={k=sample_id, v=gene exp}
    my @sample_ids;
    warnf "parsing %s...\n", $self->in_filename;
    foreach my $r (@{$self->parser->records}) {
	next unless lc ref $r eq 'sample';
	my $__table=$r->{__table} or confess "no __table";
	my $sample_id=$r->{geo_id};
	push @headers, $sample_id;

	foreach my $v (@{$__table->{data}}) {
	    my $probe_id=$v->[0];
	    my $exp=$v->[1];
	    $data{$probe_id}->{$sample_id}=$exp;
	}

    }
    delete $data{ID_REF};	# artifact

    print $fh join(',', @headers), "\n";
    @sample_ids=sort @headers;
    foreach my $probe_id (sort keys %data) {
	my $gene=$probe2sym->{$probe_id} || $probe_id;
	print $fh "$probe_id,$gene";
	foreach my $sample_id (@sample_ids) {
	    print $fh ',', $data{$probe_id}->{$sample_id} || '0';
	}
	print $fh "\n";
    }
    return $self->out_filename;
}




__PACKAGE__->meta->make_immutable;

1;
