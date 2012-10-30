#!/usr/bin/env perl 

# Turns out a lot of the text fields from GEO data has characters
# that cause utf8::downgrade to fail, which in turn f---'s up
# Catalyst.  So we have to remove all such char's from the db.

use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;			# PhonyBone::Options, sorta

use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib abs_path("$Bin/../../lib");
use GEO;
use GEO::Search;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my @args=@_;

    my $histo={};
    my $fuse=$options{fuse};

    foreach my $class (@{GEO->geo_classes}) {
	next unless $class->can('word_fields');
	my $word_fields=$class->word_fields;
	my $mongo=$class->mongo;

	my $cursor=$mongo->find;
	while ($cursor->has_next) {
	    my $record=$cursor->next;	
	    foreach my $field (@$word_fields) {
		my $source=$record->{$field} or next; # die "no '$field' in ", Dumper($record);
		$source=join(' ', @$source) if (ref $source eq 'ARRAY');
		look_for_bad_chars($source, $histo);
	    }
	    last if --$fuse==0;
	}	
    }

    no warnings;
    while (my ($o,$count)=each %$histo) {
	printf "%s (%d): %d\n", chr($o), $o, $count;
    }
}

sub look_for_bad_chars {
    my ($s, $histo)=@_;
    foreach my $c (split('', $s)) {
	my $o=ord($c);
	if ($o>=256) {
#	    printf "$c: $o\n";
	    $histo->{$o}++;
	}
    }
}

main(@ARGV);

