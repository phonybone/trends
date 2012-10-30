package TestSearch;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(TestGEO); # for method attrs, sigh...
use Test::More;
use PhonyBone::FileUtilities qw(warnf);
use Data::Dumper;
use GEO;

before qr/^test_/ => sub { shift->setup };


# do a basic search for asthma, using GEO::Sample->phenotypes
sub test_search_mongo :Testcase {
    my ($self, $st, $class, $field, $n_expected)=@_;
    my $search=$self->class->new(search_term=>$st, host=>'localhost');
    my $results=$search->search_mongo($class->mongo, $field);
    my $n_results=scalar keys %$results;
    cmp_ok($n_results, '>=', $n_expected, "got at least $n_results results for $class -> $field -> $st");
}

sub test_add_results :Testcase {
    my ($self)=@_;
    cmp_ok(GEO::Sample->mongo_coords, 'eq', 'local:geo_test:samples', 
	   sprintf "GEO::Sample: %s", GEO::Sample->mongo_coords);
    cmp_ok(GEO::Series->mongo_coords, 'eq', 'local:geo_test:series', 
	   sprintf "GEO::Series: %s", GEO::Series->mongo_coords);

    my $s=$self->class->new(search_term=>'adenocarcinoma');
    my $r1=$s->search_mongo(GEO::Sample->mongo, 'phenotypes');
    my $r1_count=0;
    while (my ($geo_id, $list)=each %$r1) {
	$r1_count+=scalar @$list;
    }

    my $dataset_mongo=GEO::Dataset->mongo;
    cmp_ok($dataset_mongo->full_name, 'eq', 'geo_test.datasets', $dataset_mongo->full_name);
    my $r2=$self->class->new(search_term=>'adenocarcinoma')->search_mongo(GEO::Dataset->mongo, 'title');
    my $r2_count=0;
    while (my ($geo_id, $list)=each %$r2) {
	$r2_count+=scalar @$list;
    }    

    $s->add_results($r1,$r2);	# $r1 now holds everything
    my $r1a_count=0;
    while (my ($geo_id, $list)=each %$r1) {
	$r1a_count+=scalar @$list;
    }    
    cmp_ok($r1_count+$r2_count, '==', $r1a_count, "$r1_count + $r2_count = $r1a_count");
    while (my ($geo_id, $list2)=each %$r2) {
	my $list1=$r1->{$geo_id};
	my $n_list1=scalar @$list1;
	my $n_list2=scalar @$list2;
	cmp_ok($n_list1, '==', $n_list2, "$geo_id: $n_list1 == $n_list2");
    }
}

sub test_consolidate : Testcase {
    my ($self, $st)=@_;
    my $s=$self->class->new(search_term=>$st);

    my $results=$s->full_search;
#    warnf "%s: before consolidate:\n%s", $st, Dumper($results);
    my $stats_before=stats($results);
#    warnf "before: %s", Dumper($stats_before);

    my ($results_c, $n_gs, $n_ds)=$s->_consolidate($results);
#    warnf "%s: after consolidate:\n%s", $st, Dumper($results);
    my $n=$n_gs+$n_ds;
    my $stats_after=stats($results_c);
    @{$stats_after}{qw(n_gs n_ds n)}=($n_gs, $n_ds, $n);
#    warnf "after: %s", Dumper($stats_after);

    # make sure all sample and subset hits were removed
    cmp_ok($stats_after->{'GEO::Sample'}, '==', 0, 'no samples');
    cmp_ok($stats_after->{'GEO::DatasetSubset'}, '==', 0, 'no samples');

    # total gds hits should be old gds hits plus subset hits
    cmp_ok($stats_before->{'n_hits'}       +
	   $stats_after->{'n'}             -
	   $stats_before->{'GEO::Sample'}, '==',
	   $stats_after->{'n_hits'},
	   "all subsets added to datasets");
}

sub test_expand : Testcase {
    my ($self, $st)=@_;
    my $s=$self->class->new(search_term=>$st);
    my $results=$s->full_search;
    $results=$s->_consolidate($results);
    $results=$s->_expand($results);

    # for each result, verify that $st appears in the field:
    while (my ($geo_id, $list)=each %$results) {
	my $geo=GEO->factory($geo_id);
	foreach my $source (@$list) {
	    my $field=$source->{field};
#	    my $orig_source=$geo->$field;

	    my $orig_source;
	    if (my $orig_geo_id=$source->{orig_geo_id}) {
		my $orig_geo=GEO->factory($orig_geo_id);
		ok ($orig_geo->can($field), sprintf "%s has method '$field'", $source->{orig_geo_id});
		$orig_source=$orig_geo->$field;
	    } else {
		ok ($geo->can($field), "$geo_id has method '$field'");
		$orig_source=$geo->$field;
	    }
	    $orig_source=join(' ', @$orig_source) if ref $orig_source eq 'ARRAY';
	    ok($orig_source =~ /$st/);
	}
    }
}

# return a hashref: k=geo class, v=count of hits
sub stats {
    my ($results)=@_;
    my $stats={'GEO::Sample'=>0,
	       'GEO::Series'=>0,
	       'GEO::Dataset'=>0,
	       'GEO::DatasetSubset'=>0,
    };
    while (my ($geo_id, $list)=each %$results) {
	$stats->{n_hits}+=scalar @$list;
	my $class=GEO->class_of($geo_id);
	$stats->{$class} += scalar @$list;
    }
    $stats;
}

sub test_results : Testcase {
    my ($self, $st)=@_;
    confess "no search term" unless $st;
    my $s=$self->class->new(search_term=>$st);
    my $results=$s->results;
    isa_ok($results, 'HASH');
    warnf "got %d results for %s", $s->count, $st;
}
1;

__END__


sub test_phenos :Testcase {
    my ($self, $st)=@_;
    my $s=$self->class->new(search_term=>$st);
    isa_ok($s, $self->class);

    my $results=$s->search_phenos();
    warnf "got %d results for %s\n", scalar keys %$results, $st;
    my $n_results=scalar keys %$results;
    ok ($n_results > 0, "got $n_results (need at least 1)") or return;
    my @geo_ids=keys %
}

sub test_word_search :Testcase {
    my ($self, $st)=@_;
    my $s=$self->class->new(search_term=>$st);
    isa_ok($s, $self->class);

    my $results=$s->search_words();
    my $n_results=scalar keys %$results;
    ok ($n_results > 0, "got $n_results (need at least 1)") or return;
}

__PACKAGE__->meta->make_immutable;

1;
