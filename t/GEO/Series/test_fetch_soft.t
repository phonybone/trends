#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use PhonyBone::FileUtilities qw(warnf);
use lib "$ENV{TRENDS_HOME}/lib";

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
    my $geo_id='GSE14777';
    my $series=GEO::Series->new(geo_id=>$geo_id);
    isa_ok ($series, $class, "instanciated GEO::Series->$geo_id");
    
    my $target=$series->soft_path . ".gz";
    warnf "removing, then fetching, %s\n", $target;
    unlink $target;
    $series->fetch_soft;
    ok (-r $target, (sprintf "downloaded %s", $target));

}

main(@ARGV);
