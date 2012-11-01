package GEO::Search;		# 'Search' as a noun, not verb

# Search (local) the GEO databases.  A GEO::Search object is a noun representing a search.
# Create a search object: 
#  my $sr=GEO::Search->new(search_term=>'some search term');
#  my $results=$sr->results;
#
# $results: a hashref w/: k=geo_id, v=list of sources
# source: a hashref w/: k='field', v=the field in geo object (indexed by geo_id) where the search term was found
#                       k='source', v=the actual source, ie $geo->$field
#            optional:  k='orig_geo_id', v=the original geo_id found (if from a subset or sample);
#                                          In this case, the 'field' entry relates to the original
#                                          geo object, ie, $orig_geo->$field.
# Entrypoint is 

use Moose;
use MooseX::ClassAttribute;
use Carp;
use GEO;
use GEO::word2geo;
use PhonyBone::FileUtilities qw(warnf);
use Data::Structure::Util qw(unbless);

has 'search_term' => (is=>'ro', isa=>'Str', required=>1);
has 'host' => (is=>'ro', isa=>'Str', default=>'localhost:3000');
has 'suffix' => (is=>'ro', isa=>'Str');
has 'results' => (is=>'ro', lazy=>1, isa=>'HashRef[ArrayRef]', 
		  builder=>'_build_results'); # k=geo_id, v=list of hashrefs
has 'unbless_results' => (is=>'ro', isa=>'Int', default=>0);

class_has 'classes' => (is=>'ro', isa=>'ArrayRef', 
			default=>sub { [qw(GEO::Sample GEO::Dataset GEO::DatasetSubset GEO::Series)] });

use PhonyBone::Benchmarks;
sub _build_results {
    my ($self)=@_;

    my $results=$self->full_search;
    $results=$self->_consolidate($results);
    $results=$self->_expand($results);
    $results=$self->_sort($results);
    
    $results;
}

# For a given search term, search through all $class->word_field entries, plus GEO::Sample->phenotypes
sub full_search {
    my ($self)=@_;
    my $all_results={};
    foreach my $class (@{$self->classes}) {
	foreach my $field (@{$class->word_fields}) {
	    my $mongo=$class->mongo;
	    my $results=$self->search_mongo($mongo, $field);
	    $self->add_results($all_results, $results);
	}
    }
    $all_results;
}

sub search_w2g {
    my ($self)=@_;
    $self->search_mongo(GEO::word2geo->mongo, 'word');
}

# core search method: searches a $mongo for $field=$self->search_term
# return a hashref: k=$geo_id, v=list of $source's (mongo->full_name + $field)
sub search_mongo {
    my ($self, $mongo, $field)=@_;
    my $st=$self->search_term;
    my $cursor=$mongo->find({$field=>qr/$st/}); 
    my $source=join(':',$mongo->full_name,$field);
    my $results={};

    while ($cursor->has_next) {
	my $record=$cursor->next;
	my $geo_id=$record->{geo_id} or next;

#	$sr=unbless $sr if $self->unbless_results;
	push @{$results->{$geo_id}}, $source;
    }
    $results;
}


# merge one results hash with another
sub add_results {
    my ($self, $all_results, $results)=@_;
    while (my ($geo_id, $results_list)=each %$results) {
	push @{$all_results->{$geo_id}}, @$results_list;
    }
}

# Consolidate the search results by:
# Moving subset results to their parent dataset;
# Removing sample results, and adding an entry to each of the
#    sample's parent series and/or datasets.
#
# In the case of a replacement, the source string has the original $geo_id
# prepended to the source string, and separated with '|'; eg, "$mongo_coords:$field"
# becomes "$orig_geo|$mongo_coords:$field".
#
# In scalar content, return the modified hashref.
# In list context, return additional debugging information (number of
#    new gse and gds entries added from samples).
sub _consolidate {
    my ($self, $results)=@_;
    my ($n_ds, $n_gs)=(0,0);
    foreach my $geo_id (keys %$results) {
	my $is_sample=$geo_id=~/^GSM\d+$/;
	my $is_subset=$geo_id=~/^GDS\d+_\d+$/;
	next unless $is_sample || $is_subset;

	# remove list and add it's contents to "parent" geo(s):
	my $list=delete $results->{$geo_id};
	foreach my $source (@$list) {
	    if ($is_sample) {
		# samples can have multilple gds or gse:
		my $sample=GEO->factory($geo_id);
		push @{$results->{$_}}, "$geo_id|$source" for @{$sample->series_ids};
		$n_gs+=scalar @{$sample->series_ids};
		push @{$results->{$_}}, "$geo_id|$source" for @{$sample->dataset_ids};
		$n_ds+=scalar @{$sample->dataset_ids};

	    } elsif ($is_subset) {		# it's a subset:
		$geo_id=~/^GDS\d+/;
		my $gds_id=$&;
		push @{$results->{$gds_id}}, "$geo_id|$source";

	    } else {
		confess "'$geo_id': not a sample or subset"; # safety check
	    }
	}
    }
    wantarray? ($results, $n_ds, $n_gs) : $results;
}

# take a source string as output by _consolidate.  Convert it to
# a hash with the following fields:
# field => name of original field
# source => value of original field
# orig_geo_id => $orig_geo_id, or non-existant

sub _source2hash {
    my ($geo_id, $source)=@_;
    my $result={};

    my $idx=index($source, '|');
    if ($idx >= 0) {
	$geo_id=substr($source, 0, $idx);
	$result->{orig_geo_id}=$geo_id;
    }

    my $geo=GEO->factory($geo_id);
    $source=~/:.*/;
    my $field=substr($&,1);
    my $orig_source=$geo->$field;
    $orig_source=join(' ',@$orig_source) if ref $orig_source eq 'ARRAY';
    if (!utf8::downgrade($orig_source, 1)) {
	$orig_source=remove_wide_chars($orig_source);
    }
    $result->{field}=$field;
    $result->{source}=$orig_source;
    $result;
}

sub _expand {
    my ($self,$results)=@_;
    while (my ($geo_id, $sources)=each %$results) {
	my $expanded=[];
	foreach my $source (@$sources) {
	    my $result=_source2hash($geo_id,$source);
	    push @$expanded,$result;
	}
	$results->{$geo_id}=$expanded;
    }
    $results;
}

# sort by:
# length of individual results list
# phenotypes > subset.description > *.title > *.description
sub _sort {
    my ($self, $results)=@_;
    warn "sort_results nyi";
    $results;
}

sub count {
    my ($self)=@_;
    scalar keys %{$self->results};
}

sub remove_wide_chars {
    my ($source)=@_;
    my @chrs=split('', $source);
    for (my $i=0; $i<length($source); $i++) {
	$chrs[$i]='?' if ord($chrs[$i])>=256;
    }
    join('', @chrs);
}

1;
