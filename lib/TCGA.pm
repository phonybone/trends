package TCGA;
use Moose;
use MooseX::ClassAttribute;
use Moose::Util::TypeConstraints;
use Carp;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);
use TCGA::Id2Path;
use namespace::autoclean;


has 'type' => (is=>'ro', isa=>'Str', required=>1);
has 'id' => (is=>'ro', isa=>'Int', required=>1);
has 'exp_data' => (is=>'ro', isa=>'HashRef', lazy=>1, builder=>'_build_data');

# k=type, v=[paths[id]]
has id2paths => (is=>'ro', 
		 isa=>'HashRef[TCGA::Id2Path]', 
		 default=>sub{{}},
		 handles=>{
		     get_path=>'get',
		 }
    );

# allow new($type, $id):
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 2 && !ref $_[0] ) {
	return $class->$orig( type => $_[0], id=>$_[1] );
    } else {
	return $class->$orig(@_);
    }
};

sub BUILD {
    my ($self)=@_;
    my $type=$self->type;
    my $class=ref $self || $self;
    die "'$type': invalid type for $class" unless TCGA::Id2Path->is_valid_type($type);
}

sub path {
    my ($self)=@_;
    my $id2path=$self->id2paths->{$self->type};
    if (!$id2path) {
	$id2path=new TCGA::Id2Path($self->type);
	$self->id2paths->{$self->type}=$id2path;
    }
    $id2path->get($self->id);
}

# return a gene->data map for this type, id:
sub _build_data {
    my ($self)=@_;
    my $exp_data={};
    my $fi=new PhonyBone::FileIterator($self->path);
    my $looks_like_gene=qr/^[\w\d_.]+$/;
    while ($fi->has_next) {
	my $line=$fi->next;
	my ($gene,$exp)=split(/\s+/, $line);
	next unless looks_like_number($exp);
	next unless $gene=~/$looks_like_gene/;
	$exp_data->{$gene}=$exp;
    }
    $exp_data;
}

sub as_csv {
    my ($self)=@_;
}


__PACKAGE__->meta->make_immutable;

1;
