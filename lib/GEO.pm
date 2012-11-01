package GEO;
use Moose;
use namespace::autoclean;

use MooseX::ClassAttribute;
use Carp;
use Data::Dumper;
use MongoDB;
use Net::FTP;
use Text::CSV;
use File::Path qw(make_path);
use File::Spec qw(catfile);
#use PhonyBone::StringUtilities qw(full_split);
use PhonyBone::FileUtilities qw(warnf dief);
use PhonyBone::ListUtilities qw(in_list);

use GEO::Dataset;
use GEO::DatasetSubset;
use GEO::Sample;
use GEO::Series;
use GEO::Platform;

has 'geo_id' => (isa=>'Str', is=>'rw', required=>1);

# fixme: might be an issue if /data is a link...
class_has 'data_dir' => (is=>'rw', isa=>'Str', default=>"$ENV{TRENDS_HOME}/data/GEO");


class_has 'ftp_link'=>     (is=>'ro', isa=>'Str', default=>'ftp.ncbi.nih.gov');
class_has 'prefix2class'=> (is=>'ro', isa=>'HashRef', default=>sub { {GSM=>'GEO::Sample',
								      GSE=>'GEO::Series',
								      GDS=>'GEO::Dataset',
								      GDS_SS=>'GEO::DatasetSubset',
								      GPL=>'GEO::Platform',
    } });
sub geo_classes { [values %{shift->prefix2class}] }

class_has 'db_name'         => (is=>'rw', isa=>'Str', default=>'geo');	
class_has 'indexes' => (is=>'rw', isa=>'ArrayRef', default=>sub { 
    [
     {keys=>['geo_id'], opts=>{unique=>1}},
    ]}
    );
class_has 'primary_key' => (is=>'ro', isa=>'Str', default=>'geo_id');
with 'Mongoid';

sub _init {
    my ($class)=@_;
    my $trends_home=$ENV{TRENDS_HOME};
    if (! -d $trends_home) {
	use FindBin qw($Bin);
	use Cwd 'abs_path';
	$trends_home=abs_path("$Bin/..");
    }
    if (! -d $trends_home) {
	die "Unable to deternmine trends home directory??? Last attempt: '$trends_home'";
    }
    
    $class->data_dir(File::Spec->catfile($trends_home, 'data', 'GEO'));
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
    if ($self->geo_id && !$self->_id) {
	eval {
	    my $record=$self->get_mongo_record; # can die if db not running
	    $self->hash_assign(%$record) if $record;
	};
	warn "error: $@" if $@;
    }
    $self;
}


# get the class from a geo_id, or undef
sub class_of { 
    my ($self, $arg)=@_;

    # sort $arg->$geo_id:
    my $geo_id;
    if (ref $self && $self->isa('GEO')) {
	$geo_id=$self->geo_id;
    } elsif (ref $arg && $arg->isa('GEO')) {
	$geo_id=$arg->geo_id; # $arg was actually a geo object
    } else {
	$geo_id=$arg;
    }
    confess "no geo_id" unless $geo_id;

    # Determine class based on prefix of $geo_id; special case of GEO::DatasetSubset
    my $prefix=substr($geo_id,0,3);
    my $class=$self->prefix2class->{$prefix} or return undef;
    $class='GEO::DatasetSubset' if $class eq 'GEO::Dataset' && $geo_id=~/GDS\d+_\d+/;
    $class;
}

########################################################################

# return the class-based prefix for geo_ids: subclasses must define
sub prefix {
    my $self=shift;
    $self = ref $self || $self;
    confess "no prefix defined for $self";
}

# sorting method: sorts alphabetically on prefix, then by number, then subset number
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

    # Get class from geo_id:
    $geo_id ||= $self->geo_id;
    confess sprintf("no geo_id in %s", Dumper($self)) unless $geo_id;
    $class=$geo_id? $self->class_of($geo_id) : (ref $self || $self);
    confess "no class for '$geo_id'" unless $class;
    my $geo=eval {$class->new($geo_id)};
    confess $@ if $@;
    $geo;
}

sub from_record {
    my $class=shift;		# need not be dst class; 
    my %record;
    if (scalar @_ == 1) {
	%record=ref $_[0] eq 'ARRAY'? @{$_[0]} : %{$_[0]};
    } else {
	%record = @_;
    }

    my $geo_id=$record{geo_id} or die "no geo_id";
    $class=$class->class_of($geo_id) or die "$geo_id: unknown class";
    $record{_id}=new MongoDB::OID(1);
    # fools BUILD into not going to db
    my $geo=$class->new(%record);
    delete $geo->{_id};
    $geo;
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
    $mongo->slave_okay(1);
    my $r=$mongo->find_one({geo_id=>$geo_id});
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

# add a geo's words of interest to the word2geo database
# called by bin/parse_series_soft.pl
# why isn't this used by bin/word2geo.pl???
sub add_to_word2geo {
    my ($self)=@_;
    $self->can('word_fields') or return $self;
    my $fields=$self->word_fields;

    # collect all the words:
    my @words;
    foreach my $field (@$fields) {
	my $value=$self->{$field};
	my @lines=ref $value eq 'ARRAY'? @$value : ($value);
	foreach my $line (@lines) {
	    push @words, split(/[-,\s.:]+/, $line);
	}
    }

    # clean up words and insert:
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

sub dump {
    my ($self)=@_;
    my $dump="    Dump:\n";
    foreach my $key (sort keys %$self) {
	my $value=$self->{$key};
	$dump.="\t$key";
	if (! ref $value) {
	    $dump.="\t$value";
	} elsif (ref $value eq 'ARRAY') {
	    $dump.=sprintf("[%d]\t%s", scalar @$value, join(', ', @$value));
	} elsif (ref $value eq 'HASH') {
	    $dump.=sprintf("{%d}\t%s", scalar %$value, join("\n\t", map{sprintf "%s => %s", $_, $value->{$_}} keys %$value));
	}
	$dump.="\n";
    }
    $dump;
}



########################################################################
# These routines are use by GEO::Search

# return a uri for this geo object, given a host and an optional suffix
# just wraps uri_for($geo_id)
sub uri {			
    my ($self, $host, $suffix)=@_;
    $self->uri_for($self->geo_id, $host, $suffix);
}

# actually build the uri:
sub uri_for {
    my ($self, $geo_id, $host, $suffix)=@_;
    my $ending=$suffix? join('.', $geo_id, $suffix) : $geo_id;
    join('/', "http://$host", 'geo', $ending);
}

# make a uri for everything where $self->{$k} looks like a geo id:
sub urify_geo_ids {
    my ($self, $host, $suffix)=@_;
    while (my ($k,$v)=each %$self) {
	if ($v =~ /^G\w\w\[_\d]+$/i) {
 	    $self->{$k}=$self->uri_for($v, $host, $suffix);
        }
    }
}




__PACKAGE__->_init();
__PACKAGE__->meta->make_immutable;

1;
