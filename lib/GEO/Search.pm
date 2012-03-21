package GEO::Search;
use Moose;
use MooseX::ClassAttribute;

use GEO;
use PhonyBone::FileUtilities qw(warnf);

has 'search_term' => (is=>'ro', isa=>'Str');

class_has 'classes' => (is=>'ro', isa=>'ArrayRef', 
			default=>sub { [qw(GEO::Sample GEO::Dataset GEO::DatasetSubset GEO::Series)] });

sub search_phenos {
    my ($self, %argHash)=@_;
    my $st=$self->search_term;

    $argHash{host}||='localhost:3000';
    $argHash{suffix}||='json';
    $argHash{results}||={};
    my $results=$argHash{results};

    foreach my $class (@{$self->classes}) {
	my $cursor=$class->mongo->find({phenotype=>$st});
	warnf "%s: got %d pheno results for %s\n", $class, $cursor->count, $st;
	while ($cursor->has_next) {
	    my $record=$cursor->next;
	    my $geo_id=$record->{geo_id} or next; # should never happen
	    push @{$results->{$geo_id}}, {
		source => 'phenotype',
		uri => GEO->uri_for($geo_id, $argHash{host}, $argHash{suffix}),
	    };
	}
    }
    $results;
}

sub search_words {
    my ($self, %argHash)=@_;
    my $st=$self->search_term;

    $argHash{host}||='localhost:3000';
    $argHash{suffix}||='json';
    $argHash{results}||={};
    my $results=$argHash{results};
    
    my $cursor=GEO::word2geo->mongo->find({word=>$st});
    warnf "got %d results for word %s\n", $cursor->count, $st;
    while ($cursor->has_next) {
	my $record=$cursor->next;
	my $geo_id=$record->{geo_id} or next; # never happens
	push @{$results->{$geo_id}}, {
	    source=>'word',
	    count=>$record->{count},
	    uri => GEO->uri_for($geo_id, $argHash{host}, $argHash{suffix}),
	};
    }
    $results;
}



1;
