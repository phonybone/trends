package ParseSoft;
use Moose;
use PhonyBone::FileUtilities qw(warnf);
use FileHandle;

# A package to parse GEO .soft files
# Main entry point is parse().  It returns a list of records, each blessed
# into a "fake" class whose name is whatever follows the '^' character
# in the first line of the block.  Each record has an entry for each '!' line
# in the block  (key/value pairs), with repeat values expanded into lists.
# Each record also has a {__table} entry, which is a two-element hash (keys are {header}
# and {table}).  If populated by the block, {header} and {table} contain the corresponding
# data table, otherwise the are empty (lists).  Otherwise, the value of {header} is a list of two-element arrays,
# corresponding to the /^#(.*) = (.*) lines of the block.  The value of {data} is a LoL (ie,
# a 2D array) containing the data.
#
# Records are returned in the list in the order they are found in the file. 
#

has 'filename' => (isa=>'Str', is=>'rw');
has '_fh' => (is=>'rw');
has 'ignore_table' => (is=>'rw');

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
	return $class->$orig( filename => $_[0] );
    } else {
	return $class->$orig(@_);
    }
};


sub parse {
    my ($self)=@_;
    my $filename=$self->filename or confess "no filename";
    local $/="\n^";
    local *FILE;

    open (FILE, $filename) or die "Can't open $filename: $!\n";
    my @blocks=<FILE>;
    close FILE;

    my $record_hash={};
    my $file_order=1;
    foreach (@blocks) {		# $_ holds each block
	my $record=$self->parse_block($_, $record_hash);
	$record->{__file_order}=$file_order++ unless defined $record->{__file_order};
	my $key=join('_', ref $record, $record->{geo_id});
	$record_hash->{$key}=$record;	# can overwrite because $record was added to in parse_block()
    }

    my @records=sort {$a->{__file_order} <=> $b->{__file_order}} values %$record_hash;
    wantarray? @records:\@records;
}


# This is going to do weird shit when blocks are revisited
sub next {
    my ($self)=@_;
    if (! $self->_fh) {
	warn "ParseSoft: trying to open ",$self->filename,"\n" if $ENV{DEBUG};
	my $fh=FileHandle->new($self->filename, "r") or 
	    die "Can't open ", $self->filename, ": $!";
	$self->_fh($fh);
    }
    local $/="\n^";
    my $fh=$self->_fh;
    my $block=<$fh>;
    unless ($block) {
	$self->_fh(undef);	# closes fh
	return undef;
    }
    $self->parse_block($block);
}



# parse an entire block, (stuff between "\n^" record separators)
sub parse_block {
    my $self=shift;
    local $_=shift;
    my $record_hash=shift || {};
    my @lines=split(/\n/);

    # get the "class" from the first line:
    my $line=shift @lines;
    my ($class, $value)=split(/\s*=\s*/, $line);
    $class=lc $class;
    $class=substr($class, 1) if substr($class, 0, 1) eq '^';

    my $key=join('_',$class,$value);
    my $record;
    if (my $old_record=$record_hash->{$key}) { # .soft files can revisit sub-records within themselves
	$record=$old_record;
    } else {
	$record=$record_hash->{$key} || {$key=>$class, geo_id=>$value};
	$record->{__table}={data=>[], header=>[]};
    }

    foreach my $whole_line (@lines) {
	chomp $whole_line;
	my $first=substr($whole_line, 0, 1);
	$line=substr($whole_line, 1);

      SWITCH: {
	  $first eq '^' and last; # going on to next record

	  $first eq '!' and do {
	      parse_bang_line($line, $record, $class);
	      last SWITCH;
	  };

	  $first eq '#' and do {
	      parse_hash_line($line, $record) unless $self->ignore_table;
	      last SWITCH;
	  };

	  # default:
	  parse_data_line($whole_line, $record) unless $self->ignore_table;
      }
    }
    bless $record, $class;	# class probably isn't a real class; more like a label for the record
}

# bang ('!') lines basically hold attr-value pairs
# in .soft files the attr is prefixed with the record type; we remove the prefix.
sub parse_bang_line {
    my ($line, $record, $class)=@_;
    my ($k,$v)=split(/\s*=\s*/, $line, 2);
    $k=lc $k;
    $k=~s/^$class//;		# remove the prefix...
    $k=~s/^_//;			# ...and the '_' char

    # values in the record can either be scalars or lists of scalars.
    # The first time a key is encountered, it is assigned with it's value
    # The second time, a listref is created and the two values are assigned to it.
    # Every time after that, the value is pushed to the list.
    if (! defined $record->{$k}) {
	$record->{$k}=$v;
    } elsif (ref $record->{$k} eq 'ARRAY') {
	push @{$record->{$k}}, $v;
    } else {
	my $old=$record->{$k};
	$record->{$k}=[$old, $v];
    }
    undef;
}

# parse a header line: split on ' = '; append to $record->{__table}->{header}
sub parse_hash_line {
    my ($line, $record)=@_;

    my ($col_name, $col_desc)=split(' = ', $line, 2);
    $col_desc=~s/Value for [^:]+:\s*//;
    push @{$record->{__table}->{header}}, [$col_name, $col_desc];
    undef;
}

# table data is a LoL; split on whitespace and append arrayref to $record->{__table}->{data}
sub parse_data_line {
    my ($line, $record)=@_;
    push @{$record->{__table}->{data}}, [split(/\s+/, $line)];
    undef;
}



1;
