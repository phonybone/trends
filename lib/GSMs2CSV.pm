package GSMs2CSV;
use Moose;

use Carp;
use Data::Dumper;
use namespace::autoclean;

use GEO::Sample;
use aliased 'PhonyBone::Hash2Daa' => 'Hash2D';
use Probe2Sym;

has 'gsms' =>      (is=>'ro', isa=>'ArrayRef[Str]', default=>sub{[]});
has 'gsm_dir' =>   (is=>'rw', isa=>'Str', default=>GEO::Sample->data_dir);
has 'table' =>     (is=>'ro', isa=>'PhonyBone::Hash2D', lazy=>1, builder=>'_build_table');
has 'probe2sym' => (is=>'ro', isa=>'Probe2Sym', default => sub { Probe2Sym->new });

# Build a 2D hash: $table->{$gsm}->{$gene}=$exp;
sub _build_table {
    my ($self)=@_;
    my $table=Hash2D->new(col0_header=>'ID_REF');
#    my $table=new Hash2D(col0_header=>'ID_REF');
    my $p2s=$self->probe2sym;

    # put in first two columns:
    my $gsm=$self->gsms->[0];
    my $sample=GEO->factory($gsm);
    while (my ($gene, $exp)=each %{$sample->exp_data}) {
	$table->put('IDENTIFIER', $gene, ($p2s->{$gene} || $gene));
    }

    foreach my $gsm (@{$self->gsms}) {
	my $sample=GEO->factory($gsm);

	while (my ($gene, $exp)=each %{$sample->exp_data}) {
#	    die "no exp for gene='$gene'" unless $exp;
	    warn "no gene???" unless $gene;
	    $table->put($gsm,$gene,($exp || 0));
	}
    }
    $table;
}


# Add a gsm to the list and return $self:
# For lists: $g2c->add_gsm($_) for @gsms;
sub add_gsm {
    my ($self, $gsm)=@_;
    eval {$gsm=$gsm->geo_id};	# If a GEO::Sample was passed in, not just the id
    # validate $gsm?
    push @{$self->gsms}, $gsm;
    $self;
}


__PACKAGE__->meta->make_immutable;

1;
