#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../../lib";
require "$FindBin::Bin/../mongo_utils.pl";

BEGIN: {
  Options::use(qw(d q v h fuse=i clear_dst=i ignore_t1 ignore_t2));
    Options::useDefaults(fuse => -1,
			 clear_dst=>1,
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

my %visited;
my $stats={};

sub main {
    my $db=shift or die Options::usage(qw(db table1 table2 join_field dst_table));
    my $t1_name=shift or die Options::usage(qw(db table1 table2 join_field dst_table));
    my $t2_name=shift or die Options::usage(qw(db table1 table2 join_field dst_table));
    my $jf=shift or die Options::usage(qw(db table1 table2 join_field dst_table));
    my $dst_name=shift or die Options::usage(qw(db table1 table2 join_field dst_table));


    my $t1=get_mongo($db,$t1_name);
    my $t2=get_mongo($db,$t2_name);
    my $dst=get_mongo($db,$dst_name);
    $dst->remove if $options{clear_dst};
    warnf "writing to $dst_name\n";

    unless ($options{ignore_t1}) {
	warnf "inserting $t1_name to $dst_name...\n";
	merge_tables($t1,$t2,$dst,$jf);
    }

    unless ($options{ignore_t2}) {
	warnf "inserting $t2_name to $dst_name...\n";
	merge_tables($t2,$t1,$dst,$jf);
    }

    warn Dumper($stats);
}

sub merge_tables {
    my ($t1,$t2,$dst,$jf)=@_;
    my $cur=$t1->find();
    warnf "%d records\n", $cur->count;
    my $fuse=$options{fuse};
    while (my $t1r=$cur->next) {
	unless ($t1r->{$jf}) {
	    warnf "no $jf in %s\n", Dumper($t1r);
	    $stats->{missing_jf}++;
	    next;
	}
	next if $visited{$t1r->{$jf}};
	$visited{$t1r->{$jf}}++;

	# find corresponding record in $t2
	my $t2r=$t2->find_one({$jf=>$t1r->{$jf}});
	unless ($t2r) {
	    warnf "no corresponding record for %s\n", $t1r->{$jf};
	    $stats->{missing_t2}++;
	    $t2r={};		# can't just do next because we still need to add to $dst
	};
	
	# merge record
	while (my ($t2k, $t2v)=each %$t2r) {
	    next if $t2k eq '_id';
	    if (defined $t1r->{$t2k}) {
		if ($t1r->{$t2k} ne $t2r->{$t2k}) {
		    warnf "$t2k: conflicting values:\n   %s\n   %s\n", $t1r->{$t2k}, $t2r->{$t2k};
		}
	    }
	    $t1r->{$t2k}=$t2v;
	    warnf "adding %s to %s\n", $t2k, $t1r->{$jf};
	}

	# insert into $dst:
	$dst->insert($t1r);
	warnf "%s inserted\n", $t1r->{$jf};
	$stats->{inserted}++;
	last if --$fuse==0;
    }
}




main(@ARGV);

