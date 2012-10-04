package TCGA::Id2Path;
use Moose;
use MooseX::ClassAttribute;
use Carp;
use Data::Dumper;
use File::Spec;
use PhonyBone::FileIterator;
use namespace::autoclean;

has 'type' => (is=>'ro', isa=>'Str', required=>1);
has 'data_dir' => (is=>'ro', isa=>'Str', required=>1);
has 'id2path' => (is=>'ro', isa=>'ArrayRef[Str]', lazy=>1, builder=>'_read_manifest');

sub manifest_fn { 
    my ($self)=@_;
    File::Spec->catfile($self->data_dir, 'MANIFEST.txt');
}

class_has 'type2subdir' => (is=>'ro', isa=>'HashRef', default=>sub{{}});
class_has 'tcga_dir' => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_build_tcga_dir');
sub _build_tcga_dir {
    "$ENV{TRENDS_HOME}/data/tcga";    
}


# allow new($type):
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args;

    if ( @_ == 1 && !ref $_[0] ) {
	$args{type}=$_[0];
    } else {
	%args=@_;
    }

    $args{data_dir} ||= $class->type2subdir->{$args{type}};

    $class->$orig(%args);
};

sub BUILD {
    my ($self)=@_;
    my $type=$self->type;
    my $class=ref $self || $self;
    die "'$type': invalid type for $class" unless $class->is_valid_type($type);
}

# return an array of file names:
sub _read_manifest {
    my ($self)=@_;
    my $manifest_fn=$self->manifest_fn;
    my $fi=new PhonyBone::FileIterator($self->manifest_fn);
    my @id2fn;
    while ($fi->has_next) {
	my $line=$fi->next;
	next unless $line=~/data.txt$/;
	chomp $line;
	my ($md5, $fn)=split(/\s+/, $line);
	push @id2fn, File::Spec->catfile($self->data_dir,$fn);
    }
    \@id2fn;
}

sub get {
    my ($self, $i)=@_;
    $self->id2path->[$i];
}

sub size {
    my ($self)=@_;
    scalar @{$self->id2path};
}

# add an entry to $class->type2subdir:
# returns $class->type2subdir->{$type} (which is the $subdir)
sub add_type {
    my ($class, $type)=@_;
    my $subdir=File::Spec->catfile($class->tcga_dir, $type);
    -d $subdir or die "$subdir: $!";
    -r $subdir or die "$subdir: $!";
    opendir(DIR,$subdir) or die $!;
    my @ssubdirs=grep {-d File::Spec->catfile($subdir,$_) && $_ !~ m|^\.|} readdir DIR;
    closedir DIR;
    die "Missing or multiple subdirs in $subdir; can't resolve\n" unless
	scalar @ssubdirs == 1;
    $subdir=File::Spec->catfile($subdir, $ssubdirs[0]);
    -r "$subdir/MANIFEST.txt" or die "no MANIFEST.txt in '$subdir'";
    $class->type2subdir->{$type}=$subdir;
}

sub is_valid_type {
    my ($class, $type)=@_;
    defined $class->type2subdir->{$type};
}

sub _init_class {
    my ($class)=@_;
    my $tcga_dir=$class->tcga_dir or die "TCGA::Id2Path: no tcga_dir (check \$ENV{TRENDS_HOME})\n";
    
    opendir(TCGA_DIR, $tcga_dir) or die "Can't open $tcga_dir: $!\n";
    my @types=grep /^\w{3,5}$/, readdir TCGA_DIR;
    close TCGA_DIR;
    $class->add_type($_) for @types;
}

__PACKAGE__->_init_class;
__PACKAGE__->meta->make_immutable;

1;
