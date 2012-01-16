package Mongoid;

# 
# "Mixin" class to provide functionality to MongoDB dbs.
#


use Moose;
use MongoDB;
use MooseX::ClassAttribute;
use PhonyBone::FileUtilities qw(warnf dief);

has '_id'    => (isa=>'MongoDB::OID', is=>'rw');	# mongo id

class_has 'db'         => (is=>'rw');
class_has 'connection' => (is=>'rw', isa=>'MongoDB::Connection');
class_has 'mongo_dbs'  => (is=>'rw', isa=>'HashRef', default=>sub {{}});

# Classes that use Mongoid must define these fields for themselves:
class_has 'db_name'         => (is=>'rw', isa=>'Str');	# classes override this on their own
class_has 'collection_name' => (is=>'rw', isa=>'Str'); # classes override this on their own


# return the mongo db (ie, collection) for this class:
# to get a collection, we need a mongodb connection and a mongodb database.
# cache by class
sub mongo {
    my ($self)=@_;
    my $class=ref $self || $self;
    if (my $mongo=$self->mongo_dbs->{$class}) { return $mongo; }
    confess "no db_name for $class" unless $class->db_name;

    if (! defined $class->db) {
	$self->connection(MongoDB::Connection->new) unless $self->connection; # connect if haven't already done so
#	$class->db_name($class->db_name.'_test') if $class->testing;
	my $db_name=$class->db_name;
	$class->db($self->connection->$db_name); # get db
#	warnf "got db %s for $class\n", ref $class->db, $class if $ENV{DEBUG};
    }

    my $collection_name=$class->collection_name or confess "no collection_name for '$class'";
    my $collection=$class->db->$collection_name;
#    warnf "got collection %s:%s for %s\n", $class->db_name, $class->collection_name, $class if $ENV{DEBUG};
    $self->mongo_dbs->{$class}=$collection;
    $collection;
}


########################################################################

sub insert {
    my ($self, $options)=@_;
    $self->mongo->insert($self, $options);
    $self;
}

# update a record, using _id.
# Omits keys starting with '_'
# $opts is a hashref; accepted keys are 'upsert', 'multiple'.
sub update {
    my ($self, $opts)=@_;
    my $record={};
    while (my ($k,$v)=each %$self) { # copy fields to new record, ...
	$record->{$k}=$v unless $k=~/^_/; # ...skipping "_keys"
    }
    my $_id=$self->mongo->save($record, $opts);
    $self->_id($_id) unless $_id eq 1; # see perldoc MongoDB::Collection, 'save'
    $self;
}

# Delete self, via _id:
sub delete {
    my ($self)=@_;
    $self->mongo->remove({_id=>$self->_id});
    $self;
}    

# remove all the dups of a record
# NOT threadsafe; works by removing all instances of record, the re-inserting
# Also changes _id, which might be bad; should be used only with classes that don't care
sub remove_dups {
    my ($self, $options)=@_;
    my $collection=$self->mongo;
    
    # Can't use blessed refs in mongo->remove, I think:
    my $class=ref $self;
    unbless $self;		# arrgghh!  It burns!
    delete $self->{_id};	# It's ripping my soul away!

    $collection->remove($self, $options); # removes all matching
    $collection->insert($self); # put one copy back in
    bless $self, $class;	# ahhhh...
}




1;
