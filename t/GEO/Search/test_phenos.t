#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf);

use Test::More qw(no_plan);

use FindBin;
use Cwd 'abs_path';
use lib abs_path("$FindBin::Bin/../../../lib");
our $class='GEO::Search';



BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    test_phenos('adenocarcinoma');
    test_word_search('cancer');
}

sub test_phenos {
    my ($st)=@_;
    my $s=GEO::Search->new(search_term=>$st);
    isa_ok($s, $class);

    my $results=$s->search_phenos();
    warnf "got %d results for %s\n", scalar keys %$results, $st;

    my $geo_id=(keys %$results)[0];
    my $record=$results->{$geo_id};
    warn Dumper($record);
}

sub test_word_search {
    my ($st)=@_;
    my $s=GEO::Search->new(search_term=>$st);
    isa_ok($s, $class);

    my $results=$s->search_words();
    warnf "got %d results for %s\n", scalar keys %$results, $st;

    my $geo_id=(keys %$results)[0];
    my $record=$results->{$geo_id};
    warn Dumper($record);
}

main(@ARGV);

