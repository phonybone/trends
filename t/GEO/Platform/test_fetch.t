#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use LWP::UserAgent;

use FindBin;
use lib "$FindBin::Bin/../../..";

our $class='GEO::Platform';



BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    confess "obsolete";
    my $gpl96=GEO::Platform->new(geo_id=>'GPL96')->fetch(new LWP::UserAgent);
    my $record=$gpl96->as_record;
    
    my $stuff={geo_id=>'GPL96', 
	       Status=>'Public on Mar 11, 2002', 
	       Title=>'[HG-U133A] Affymetrix Human Genome U133A Array',
	       'Technology type'=>'in situ oligonucleotide',
	       Distribution=>'commercial',
	       Organism=>'Homo sapiens',
	       Manufacturer=>'Affymetrix',
	       'Manufacture protocol'=>"see manufacturer's web site",
	   };

    while (my ($k,$v)=each %$stuff) {
	is($record->{$k}, $stuff->{$k}, "got $k=$v");
    }

}

main(@ARGV);

