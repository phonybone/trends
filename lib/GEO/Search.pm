package GEO::Search;		# 'Search' as a noun, not verb
use Moose;
use MooseX::ClassAttribute;


use GEO;
use GEO::word2geo;
use GEO::SearchResult;
use PhonyBone::FileUtilities qw(warnf);
use Data::Structure::Util qw(unbless);

has 'search_term' => (is=>'ro', isa=>'Str', required=>1);
has 'host' => (is=>'ro', isa=>'Str', default=>'localhost:3000');
has 'suffix' => (is=>'ro', isa=>'Str');
has 'results' => (is=>'ro', lazy=>1, isa=>'HashRef[ArrayRef]', 
		  builder=>'full_search'); # k=geo_id, v=list of GEO::SearchResult
has 'unbless_results' => (is=>'ro', isa=>'Int', default=>0);

class_has 'classes' => (is=>'ro', isa=>'ArrayRef', 
			default=>sub { [qw(GEO::Sample GEO::Dataset GEO::DatasetSubset GEO::Series)] });



# For a given search term, search through all $class->word_field entries, plus GEO::Sample->phenotypes
sub full_search {
    my ($self)=@_;
    my $all_results={};
    foreach my $class (@{$self->classes}) {
	foreach my $field (@{$class->word_fields}) {
	    my $results=$self->search_mongo($class->mongo, $field);
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
    my $source_prefix=$mongo->full_name;
    my $results={};

    while ($cursor->has_next) {
	my $record=$cursor->next;
	my $geo_id=$record->{geo_id} or next;
	my $sr=new GEO::SearchResult(geo_id=>$geo_id,
				     source=>join(':',$source_prefix,$field),
	    );
	$sr=unbless $sr if $self->unbless_results;
	push @{$results->{$geo_id}}, $sr;
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

# sort by:
# length of individual results list
# phenotypes > subset.description > *.title > *.description
sub sort_results {
    my ($self, $all_results)=@_;
}

sub count {
    my ($self)=@_;
    scalar keys %{$self->results};
}

1;
