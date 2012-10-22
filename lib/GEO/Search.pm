package GEO::Search;		# 'Search' as a noun, not verb
use Moose;
use MooseX::ClassAttribute;


use GEO;
use GEO::SearchResult;
use PhonyBone::FileUtilities qw(warnf);

has 'search_term' => (is=>'ro', isa=>'Str', required=>1);
has 'host' => (is=>'ro', isa=>'Str', required=>1);
has 'suffix' => (is=>'ro', isa=>'Str', required=>1);
has 'results' => (is=>'ro', isa=>'HashRef[GEO::SearchResult]', default=>sub{{}}); # k=geo_id, v=list of GEO::SearchResult

class_has 'classes' => (is=>'ro', isa=>'ArrayRef', 
			default=>sub { [qw(GEO::Sample GEO::Dataset GEO::DatasetSubset GEO::Series)] });

sub full_search {
    my ($self)=@_;
    
}

# core search method: searches a $mongo for $field=$self->search_term
# return a hashref: k=$geo_id, v=list of GEO::SearchResult
sub search_mongo {
    my ($self, $mongo, $field)=@_;
    my $st=$self->search_term;
    my $cursor=$mongo->find({$field=>$st}); 
    my $source_prefix=$mongo->full_name;
    my $results={};
    while ($cursor->has_next) {
	my $record=$cursor->next;
	my $geo_id=$record->{geo_id} or next;
	my $sr=new GEO::SearchResult(geo_id=>$geo_id,
				source=>join(':',$source_prefix,$field),
				uri => GEO->uri_for($geo_id, $self->host, $self->suffix),
	    );
	push @{$results->{$geo_id}}, $sr;
    }
    $results;
}





1;
