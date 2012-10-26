package GEO::Search;		# 'Search' as a noun, not verb
use Moose;
use MooseX::ClassAttribute;
use Carp;

use GEO;
use GEO::word2geo;
use GEO::SearchResult;
use PhonyBone::FileUtilities qw(warnf);
use Data::Structure::Util qw(unbless);

has 'search_term' => (is=>'ro', isa=>'Str', required=>1);
has 'host' => (is=>'ro', isa=>'Str', default=>'localhost:3000');
has 'suffix' => (is=>'ro', isa=>'Str');
has 'results' => (is=>'ro', lazy=>1, isa=>'HashRef[ArrayRef]', 
		  builder=>'_build_results'); # k=geo_id, v=list of GEO::SearchResult
has 'unbless_results' => (is=>'ro', isa=>'Int', default=>0);

class_has 'classes' => (is=>'ro', isa=>'ArrayRef', 
			default=>sub { [qw(GEO::Sample GEO::Dataset GEO::DatasetSubset GEO::Series)] });

sub _build_results {
    my ($self)=@_;
    my $results=$self->full_search;
    $self->_consolidate($results);
    $self->_sort($results);
    $results;
}

# For a given search term, search through all $class->word_field entries, plus GEO::Sample->phenotypes
sub full_search {
    my ($self)=@_;
    my $all_results={};
    foreach my $class (@{$self->classes}) {
	foreach my $field (@{$class->word_fields}) {
	    my $mongo=$class->mongo;
#	    warnf "Search::full_search: searching %s:%s\n", $mongo->full_name, $field;
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
# return a hashref: k=$geo_id, v=list of GEO::SearchResult
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
	push @{$results->{$geo_id}}, join(':', $source);
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

1;
