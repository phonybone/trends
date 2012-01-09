#!/usr/bin/env perl 

# 
# Clean up dropped files in a directory.  Moves them to correct location.
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Path qw(make_path);

use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $dir=$ARGV[0] || '.';
    opendir(DIR, $dir) or die "Can't open '$dir': $!\n";
    my @files=grep /^(GSM|GSE|GPL|GDS)\d+/, readdir DIR;
    closedir DIR;
    warnf "got %d GEO files in %s\n", scalar @files, $dir;

    foreach my $f (@files) {
	next if -d $f;		# if we got a directory by mistake
	$f=~/^(GSM|GSE|GPL|GDS)\d+/;
	my $geo_id=$&;
	my $geo=GEO->factory($geo_id);
	my $geo_dir=$geo->path;
	unless (-d $geo_dir) {
	    make_path $geo_dir or die "Can't make_path $geo_dir: $!\n";
	    warn "$geo_dir\n" unless $options{q};
	}

	my @cmd=('/bin/mv', $f, $geo_dir);
	system(@cmd);
    }
}



main(@ARGV);

