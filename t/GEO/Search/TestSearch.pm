package TestSearch;
use namespace::autoclean;

use Moose;
extends 'TestGEO';
use parent qw(PhonyBone::TestCase); # for method attrs, sigh...
use Test::More;
use PhonyBone::FileUtilities qw(warnf);
use Data::Dumper;
use GEO;

before qr/^test_/ => sub { shift->setup };


sub test_search_mongo :Testcase {
    my ($self)=@_;
    my $search=$self->class->new(search_term=>'asthma', host=>'localhost', suffix=>'json');
    my $results=$search->search_mongo(GEO::Sample->mongo, 'phenotypes');
    warnf "got %d results\n", scalar keys %$results;
    my $geo_id=(keys %$results)[0];
    warnf "results[$geo_id]: %s", Dumper($results->{$geo_id});
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
