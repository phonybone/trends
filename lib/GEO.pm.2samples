package GEO;
use Moose;
use MooseX::ClassAttribute;
use Carp;
use Data::Dumper;
use MongoDB;
use Net::FTP;
use Data::Structure::Util qw(unbless);
use Text::CSV;
use Devel::Size qw(size total_size);

use GEO::Dataset;
use GEO::DatasetSubset;
use GEO::RawSample;
use GEO::Series;
use GEO::SeriesData;
use GEO::Platform;
use GEO::word2geo;

use PhonyBone::FileUtilities qw(warnf dief);

has '_id'    => (isa=>'MongoDB::OID', is=>'rw');	# mongo id
has 'geo_id' => (isa=>'Str', is=>'rw', required=>1);
has 'record' => (is=>'rw', isa=>'HashRef'); # 

our %mongos=();
class_has 'data_dir' => (is=>'rw', isa=>'Str', default=>'/proj/price1/vcassen/trends/data/GEO');
class_has 'db'       => (is=>'rw');
class_has 'db_name'  => (is=>'rw', isa=>'Str', default=>'geo');

class_has 'testing' =>     (is=>'rw', isa=>'Int', default=>0);
class_has 'ftp_link'=>     (is=>'ro', isa=>'Str', default=>'ftp.ncbi.nih.gov');
class_has 'prefix2class'=> (is=>'ro', isa=>'HashRef', default=>sub { {GSM=>'GEO::RawSample',
								      GSE=>'GEO::Series',
								      GDS=>'GEO::Dataset',
								      GDS_SS=>'GEO::DatasetSubset',
								      GPL=>'GEO::Platform',
								      w2g=>'GEO::word2geo',
								      gsd=>'GEO::SeriesData', # hmmm....
								  } });

# get the class from a geo_id
sub class_of { 
    my ($self, $geo_id)=@_;
    my $prefix=substr($geo_id,0,3);
    my $class=$self->prefix2class->{$prefix} or die "no class for $prefix\n";
    $class='GEO::DatasetSubset' if $class eq 'GEO::Dataset' && $geo_id=~/GDS\d+_\d+/;
    $class;
}

class_has 'indexes' => (is=>'rw', isa=>'ArrayRef', default=>sub { [{geo_id=>1},{unique=>1}] });

# "private" class variables
our $connection;
our $db;


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
	while (my ($k,$v)=each %$record) {
	    next unless $self->can($k);
	    $self->$k($v);
	}
    }
    $self;
}

# Assign the contents of a hash to a geo object.  Extract each field of hash for which
# a geo accessor exists.
# Returns $self
sub hash_assign {
    my ($self, @args)=@_;
    my %hash=@args;
    while (my ($k,$v)=each %hash) {
	$self->$k($v) if $self->can($k);
    }
    $self;
}

########################################################################

# return the class-based prefix for geo_ids: subclasses must define
sub prefix {
    my $self=shift;
    $self = ref $self || $self;
    confess "no prefix defined for $self";
}


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
# factory() checks SeriesData db if $class=='RawSample' and no record is found
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

    # make an object and return it; special check if RawSamples if record not found
    my $geo=$class->new($geo_id);
    return $geo if defined $geo->_id || $class ne 'GEO::RawSample';

    # $class='GEO::RawSample' and $geo_id not found in db; try looking in SeriesData
    # this may be a terrible hack
    my $gds=GEO::SeriesData->new($geo_id);
    defined $gds->_id? $gds : $geo; # return $gds if found in db, original $geo otherwise
}

sub next {
    my ($self)=@_;
    my $class=ref $self || $self;
    confess "$self does not implement next()";
}

########################################################################

# return the mongo collection for the given type; also cache it (based on class prefix)
# can call as class method
sub mongo {
    my ($self, $class)=@_;

    # new:
    $class ||= ref $self || $self;
    my $prefix=$class->prefix or die "no prefix defined for $class";

    # check for cached collection:
    if (my $mongo=$mongos{$prefix}) { return $mongo; }
    
    if (! defined $db) {
	$connection||=MongoDB::Connection->new; # connect if haven't already done so
	$class->db_name($class->db_name.'_test') if $class->testing;
	my $db_name=$class->db_name;
	$db=$connection->$db_name;
	$self->db($db);
    }

    my $coll_name=$class->collection; # wow, could your naming get any worse?
    my $collection=$db->$coll_name;

    $mongos{$prefix}=$collection;
    foreach my $index (@{$class->indexes}) {
	$collection->ensure_index($index);
    }
    $collection;
}

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

sub insert {
    my ($self, $options)=@_;
    $self->mongo->insert($self, $options);
    $self;
}

# update a record
# $opts is a hashref; accepted keys are 'upsert', 'multiple'.
sub update {
    my ($self, $opts)=@_;
    $self->mongo->update({geo_id=>$self->geo_id}, $self, $opts);
    $self;
}

sub delete {
    my ($self)=@_;
    $self->mongo->remove({geo_id=>$self->geo_id});
    $self;
}    

# remove all the dups of a record
# NOT threadsafe; works by removing all instances of record, the re-inserting
sub remove_dups {
    my ($self, $options)=@_;
    my $collection=$self->mongo;
    
    my $class=ref $self;
    unbless $self;		# arrgghh!  It burns!
    delete $self->{_id};	# It's ripping my soul away!

    $collection->remove($self, $options); # removes all matching
    $collection->insert($self); # put one copy back in
    bless $self, $class;	# ahhhh...
}

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
    $ftp->login('anonymous', 'phonybone@gmail.com') or dief "Can't login to %s: msg=%s\n", $self->ftp_link, $ftp->message;
    warn "login successful" if $ENV{DEBUG};
    $ftp->binary;
    $ftp;
}


########################################################################

sub data_table_file { join('/', $_[0]->path, join('.', $_[0]->geo_id, 'table.data')) }

sub write_table {
    my ($self, $table, $dest_file)=@_;
    
    $dest_file ||= $self->data_table_file;
    mkdir $self->path unless -d $self->path;

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

1;
