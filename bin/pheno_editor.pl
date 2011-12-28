#!/usr/bin/perl

#
# A cmd-line utility to edit phenotypes in the GEO database:
# 
# Commands:
# 'n': next record
# 'N': next unedited record
# 'p': previous record
# 'q' or 'Q': quit
# 'c' <word>: cull word from db
# 'a' <word>: add this phenotype to the record
# 'r' <word>: remove this phenotype from the record
#

use strict;
use warnings;
use Carp;

use File::Spec qw(catfile);
use MongoDB;
use Term::ReadLine;

#use lib "$ENV{HOME}/Dropbox/sandbox/perl";
#use lib "$ENV{HOME}/Dropbox/sandbox/perl/PhonyBone";
use Options;
use PhonyBone::FileUtilities qw(warnf dief);
require 'mongo_utils.pl';

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;

BEGIN: {
  Options::use(qw(d q v h fuse=i db_name=s collection=s));
    Options::useDefaults(fuse => -1, delay => 5,
			 db_name=>'geo', collection=>'series',
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main {
    local @ARGV=@_;

    my $term=new Term::ReadLine 'phenotype editor';
    my $out=$term->OUT || \*STDOUT;
    
    my $collection=shift @ARGV || 'series';
    my $i=0;
    my $curr_geo;
    ($curr_geo, $i)=get_geo(0, 0);
    print $curr_geo->report;
	
    my %cmds=(n=> sub { get_geo($i, 1) },
	      N=> \&get_next_unedited,
	      p=> sub { get_geo($i, -1) }, 
	      c=> \&cull,
	      a=> \&add_pheno,
	      r=> \&remove_pheno,
	      u=> sub { $collection=$_[1]; $curr_geo; },
	      );

    
    my $prompt=sprintf("%d: %s> ", $i, $curr_geo->geo_id);
    while (defined ($_=$term->readline($prompt))) {
	chomp;
	next if /^\s*$/;	# skip blank lines
	last if /q/i;		# quit if asked
	my @args=split(/\s+/);	# split into args
	my $cmd=shift @args;	# cmd is the first arg
	my $subref=$cmds{$cmd} or do { # get the matching subref...
	    print "Unknown cmd '$cmd'\n"; # ...barf if not found
	    next;
	};

	($curr_geo, $i)=$subref->(@args); # all commands must return a $geo object
	print $curr_geo->report;
	
	$prompt=sprintf("%d: %s> ", $i, $curr_geo->geo_id); # prompt and repeat
    }
}

sub get_geo {
    my ($i, $inc)=@_;
    $i+=$inc;
    $i=0 if $i<0;		# fixme: something about if $i > number of items in db

    my $record=get_mongo($options{db_name}, $options{collection})->find()->skip($i)->limit(1)->next;
    my $geo_id=$record->{geo_id} or dief "no geo_id in %s", Dumper($record);
    my $class=GEO->class_of($record->{geo_id}) or dief "no class for %s", $record->{geo_id};
    ($class->new(%$record), $i);
}

main(@ARGV);
