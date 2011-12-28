#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf);
use PhonyBone::TimeUtilities qw(tlm);
use Test::More qw(no_plan);

use FindBin;
use lib "$FindBin::Bin/../..";

our $class='GEO';
use GEO::Series;


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    $class->testing(1);

    my $geo_id='GSE14777';
    my $series=GEO::Series->new($geo_id);

    my $date='';
    if ($series->_id) {		# was found in db:
	$date=$series->date;
	$series->date('');
	$series->update;
    } else {			# wasn't in db
	$series->insert;
    }

    my $s2=GEO::Series->new($geo_id);
    is($s2->date, $date, "got date=$date");

    # now put a current date in:
    my @time=localtime;
    my $mon=tlm($time[4]);
    $date=sprintf("%d%s%d", $time[3], $mon, $time[5]);
    $series->date($date);
    $series->update;

    # and get it back out:
    $s2=GEO::Series->new($geo_id);
    is($s2->date, $date, "got date=$date");

    
}

main(@ARGV);

