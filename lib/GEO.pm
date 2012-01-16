package GEO;
use Moose;
extends 'Mongoid';

use MooseX::ClassAttribute;
use Carp;
use Data::Dumper;
use MongoDB;
use Net::FTP;
use Data::Structure::Util qw(unbless);
use Text::CSV;
use Devel::Size qw(size total_size);
use File::Basename;
use File::Path qw(make_path);

use GEO::Dataset;
use GEO::DatasetSubset;
use GEO::Sample;
use GEO::Series;
use GEO::Platform;
use GEO::word2geo;

use PhonyBone::FileUtilities qw(warnf dief);
use PhonyBone::ListUtilities qw(in_list);

has 'geo_id' => (isa=>'Str', is=>'rw', required=>1);
#has 'record' => (is=>'rw', isa=>'HashRef'); # 

our %mongos=();
class_has 'data_dir' => (is=>'rw', isa=>'Str', default=>'/mnt/price1/vcassen/trends/data/GEO');

class_has 'testing' =>     (is=>'rw', isa=>'Int', default=>0);
class_has 'ftp_link'=>     (is=>'ro', isa=>'Str', default=>'ftp.ncbi.nih.gov');
class_has 'prefix2class'=> (is=>'ro', isa=>'HashRef', default=>sub { {GSM=>'GEO::Sample',
								      GSE=>'GEO::Series',
								      GDS=>'GEO::Dataset',
								      GDS_SS=>'GEO::DatasetSubset',
								      GPL=>'GEO::Platform',
								      w2g=>'GEO::word2geo',
								  } });

class_has 'db_name'         => (is=>'rw', isa=>'Str', default=>'geo');	
class_has 'indexes' => (is=>'rw', isa=>'ArrayRef', default=>sub { [{geo_id=>1},{unique=>1}] });

sub _init {
    my ($class)=@_;
    if (defined $ENV{TRENDS_HOME}) {
	$class->data_dir(join('/', $ENV{TRENDS_HOME}, 'data', 'GEO'));
    } else {
	$class->data_dir(join('/', '/mnt/price1/vcassen/trends', 'data', 'GEO'));
    }
    warnf "data_dir: %s\n", $class->data_dir;
}


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	return $class->$orig( geo_id => $_[0] );
    } else {
	return $class->$orig(@_);
    }
};

sub BUILD { 
    my $self=shift;
    return $self if ref $self eq 'GEO::word2geo'; # we don't need to init the object from the db
    
    if ($self->geo_id && !$self->_id) {
#	warnf "BUILD: fetching record for %s (%s)\n", $self->geo_id, (ref $self || $self) if $ENV{DEBUG};
	my $record=$self->get_mongo_record;
	$self->hash_assign(%$record);
    }
    $self;
}


# get the class from a geo_id
sub class_of { 
    my ($self, $geo_id)=@_;
    my $prefix=substr($geo_id,0,3);
    my $class=$self->prefix2class->{$prefix} or confess "no class for $geo_id\n";
    $class='GEO::DatasetSubset' if $class eq 'GEO::Dataset' && $geo_id=~/GDS\d+_\d+/;
    $class;
}


# "private" class variables
#our $connection;
#our $db;



# Assign the contents of a hash to a geo object.  Extract each field of hash for which
# a geo accessor exists.
# Returns $self
sub hash_assign {
    my ($self, @args)=@_;
    confess "ref found where list needed" if ref $args[0]; # should be a hash key
    my %hash=@args;
    while (my ($k,$v)=each %hash) {
	$self->{$k}=$v unless $k=~/^_/;
    }
    $self;
}

sub record {
    my ($self)=@_;
    my %record=%$self;
    unbless \%record;
    wantarray? %record:\%record;
}
########################################################################

# return the class-based prefix for geo_ids: subclasses must define
sub prefix {
    my $self=shift;
    $self = ref $self || $self;
    confess "no prefix defined for $self";
}

# sorting method:
sub by_geo_id($$) {
    my $_a=shift;
    my $_b=shift;

    $_a=~/^(G\w\w)(\d+)(_(\d+))?/ or die "a. can't sort on $_a";
    my ($_a_prefix, $_a_num, undef, $_a_index)=($1,$2,$3, $4);
    $_b=~/^(G\w\w)(\d+)(_(\d+))?/ or die "b. can't sort on $_b";
    my ($_b_prefix, $_b_num, undef, $_b_index)=($1,$2,$3, $4);
    
    # prefix's first:
    my $r=$_a_prefix cmp $_b_prefix;
    return $r if $r;

    # prefix's are the same, so try number:
    return $_a_num <=> $_b_num if $_a_num <=> $_b_num;

    # last is index:
    return  1 if ($_a_index && ! $_b_index);
    return -1 if ($_b_index && ! $_a_index);
    return 0 if (!$_a_index && !$_b_index);
    return $_a_index <=> $_b_index;
    
}

# return a GEO object as per the following params:
# $class, if present
# $geo_id, using extracted prefix
# $self, with geo_id as an attribute of $self
sub factory {
    my ($self, $geo_id, $class)=@_;

#   $class ||= ref $self || $self;
#   if ($class eq 'GEO') {
#	confess "no geo_id" unless $geo_id;
#	$class=$self->class_of($geo_id);
#   }

    # Get class from geo_id:
    $geo_id ||= $self->geo_id;
    confess sprintf("no geo_id in %s", Dumper($self)) unless $geo_id;
    $class=$self->class_of($geo_id) if $geo_id;	# when
    my $geo=$class->new($geo_id);
}


########################################################################

# fetch the geo record for this geo item
# pass $class to force collection
# return undef if no matches
sub get_mongo_record {
    my ($self, $geo_id, $class)=@_;
    $geo_id ||= $self->geo_id if ref $self;
    confess "no geo_id" unless $geo_id;

    # set $class
    unless ($class) {
	if (ref $self) {
	    $class = ref $self;
	} else {
	    $class=$self->class_of($geo_id);
	}
    }

    my $mongo=$class? $class->mongo : $self->mongo;
    $mongo->find_one({geo_id=>$geo_id});
}

# class method to look up lots of records in the db:
sub get_mongo_records {
    my ($self, $query, $fields)=@_;
    $query={} unless defined $query;
    confess "no/bad query hash" unless ref $query eq 'HASH';
    my @args=($query);

    if (defined $fields) {
	confess "bad fields: not a hashref" unless ref $fields eq 'HASH';
	push @args, $fields;
    }

    my @records=$self->mongo->find(@args)->all;
    wantarray? @records:\@records;
}

#-----------------------------------------------------------------------


########################################################################

sub fetch_ncbi {
    my ($self)=@_;
    $self->_fetch_tarfile;
    $self->_unpack_tar;
}

# get an NET::FTP object and log in to NCBI site
sub _get_ftp {
    my $self=shift;
    warnf("trying to connect to %s", $self->ftp_link) if $ENV{DEBUG};
    my $ftp=Net::FTP->new($self->ftp_link) or die "Can't connect to $self->ftp_link: $!\n";
    warnf("trying to login to %s", $self->ftp_link) if $ENV{DEBUG};
    $ftp->login('anonymous', 'phonybone@gmail.com') or 
	dief "Can't login to %s: msg=%s\n", $self->ftp_link, ($ftp->message || 'unknown error');
    warn "login successful" if $ENV{DEBUG};
    $ftp->binary;
    $ftp;
}


########################################################################
# add a value to an attribute that is a list.  If the attribute exists 
# but is not already a list, make it one.
# returns the list, but does not update the db
sub append {
    my ($self, $attr, $value, $opts)=@_;
    confess "missing args" unless defined $value;
    $opts||={};
    
    my $list=$self->{$attr} || [];
    $list=[$list] unless ref $list eq 'ARRAY';
    push @$list, $value if !($opts->{unique} && in_list($list, $value));
    $self->{$attr}=$list;
    $self;			# so you can chain
}

########################################################################

sub data_table_file { join('/', $_[0]->path, join('.', $_[0]->geo_id, 'table.data')) }

sub write_table {
    my ($self, $table, $dest_file)=@_;
    $table||=$self->{__table} or confess "no __table";
    $dest_file ||= $self->data_table_file;
    make_path $self->path unless -d $self->path;
    warnf "%s: path is %s (exists: %d)\n", $self->geo_id, $self->path, -d $self->path if $ENV{DEBUG};

    warnf "%s (%s): writing data table to %s\n", $self->geo_id, ref $self, $dest_file if $ENV{DEBUG};
    my $csv=new Text::CSV {binary=>1};
    open my $fh, ">", $dest_file or dief("Can't open %s for writing: %s", $dest_file, $!);

    my $header=$table->{header} or confess "no header???";
    print $fh join(',', map {$_->[1]} @$header); # fixme: intimate knowledge of ParseSoft required
    print $fh "\n";

    foreach my $row (@{$table->{data}}) {
	$csv->print($fh, $row);
	print $fh "\n";
    }
    $fh->close;
}

########################################################################

sub add_to_word2geo {
    my ($self)=@_;
    $self->can('word_fields') or return $self;
    my $fields=$self->word_fields;
    my @words;
    foreach my $field (@$fields) {
	my $value=$self->{$field};
	my @lines=ref $value eq 'ARRAY'? @$value : ($value);
	foreach my $line (@lines) {
	    push @words, split(/[-,\s.:]+/, $line);
	}
    }

    foreach my $word (@words) {
	$word=lc $word;
	$word=~s/[^\w\d_]//g;	# remove junk
	GEO::word2geo->mongo->insert({word=>$word, geo_id=>$self->{geo_id}}); # index prevents dups
	warnf("inserting %s->%s\n", $word, $self->{geo_id}) if $ENV{DEBUG};
    }
    $self;
}

########################################################################

# "tie" (not perl tie) $self to another GEO object.
# This means taking the $geo_id from the other object 
# and appending it to the $id_field as given.
#
# The second GEO object can also be an unblessed hash, so long as
# $record->{geo_id} exists, or even just a $geo_id
#
# returns $self.

sub tie_to_geo {
    my ($self, $record, $id_field)=@_;

    my $target_id=ref $record? $record->{geo_id} : $record;
    confess "no target_id" unless $target_id;

    $self->append($id_field, $target_id, {unique=>1}); # append to dataset_ids
    warnf "tied %s to %s\n", $target_id, $self->geo_id if $ENV{DEBUG};

    if (0) {
	# check for $id_field w/o the tailing 's':
	if ($id_field=~/s$/) {
	    $id_field=~s/s$//;		# remove trailing 's'
	    if (defined $self->{$id_field} && !ref $self->{$id_field}) { 
		$self->append("${id_field}s", $self->{$id_field}, {unique=>1});
		delete $self->{$id_field};
	    }
	}
    }
    $self->update({upsert=>1}); # aannnd update
    $self;
}

# this has some whitespace
__PACKAGE__->_init();

1;
