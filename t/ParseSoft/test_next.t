#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use Cwd qw(abs_path);
use File::Spec;

use lib abs_path("$FindBin::Bin/../../../lib");
use GEO;

our $class='ParseSoft';
our $trends_dir=abs_path("$FindBin::Bin/../../.."); # can't use this in 'use lib' because it's not set until runtime

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);

    my $geo_id='GSE10072';
    my $series=GEO->factory($geo_id);
    my $soft_file=$series->soft_path;
    $soft_file=~s/\.gz$//;
    my $parser=$class->new($soft_file);
    isa_ok($parser, $class, "got $class");

    my $classes=[['database','GeoMiame'],['series','GSE10072'],['platform','GPL96'],['sample','GSM254625'],['sample','GSM254626'],
		 ['sample','GSM254627'],['sample','GSM254628'],['sample','GSM254629'],['sample','GSM254630'],['sample','GSM254631'],['sample','GSM254632'],
		 ['sample','GSM254633'],['sample','GSM254634'],['sample','GSM254635'],['sample','GSM254636'],['sample','GSM254637'],['sample','GSM254638'],
		 ['sample','GSM254639'],['sample','GSM254640'],['sample','GSM254641'],['sample','GSM254642'],['sample','GSM254643'],['sample','GSM254644'],
		 ['sample','GSM254645'],['sample','GSM254646'],['sample','GSM254647'],['sample','GSM254648'],['sample','GSM254649'],['sample','GSM254650'],
		 ['sample','GSM254651'],['sample','GSM254652'],['sample','GSM254653'],['sample','GSM254654'],['sample','GSM254655'],['sample','GSM254656'],
		 ['sample','GSM254657'],['sample','GSM254658'],['sample','GSM254659'],['sample','GSM254660'],['sample','GSM254661'],['sample','GSM254662'],
		 ['sample','GSM254663'],['sample','GSM254664'],['sample','GSM254665'],['sample','GSM254666'],['sample','GSM254667'],['sample','GSM254668'],
		 ['sample','GSM254669'],['sample','GSM254670'],['sample','GSM254671'],['sample','GSM254672'],['sample','GSM254673'],['sample','GSM254674'],
		 ['sample','GSM254675'],['sample','GSM254676'],['sample','GSM254677'],['sample','GSM254678'],['sample','GSM254679'],['sample','GSM254680'],
		 ['sample','GSM254681'],['sample','GSM254682'],['sample','GSM254683'],['sample','GSM254684'],['sample','GSM254685'],['sample','GSM254686'],
		 ['sample','GSM254687'],['sample','GSM254688'],['sample','GSM254689'],['sample','GSM254690'],['sample','GSM254691'],['sample','GSM254692'],
		 ['sample','GSM254693'],['sample','GSM254694'],['sample','GSM254695'],['sample','GSM254696'],['sample','GSM254697'],['sample','GSM254698'],
		 ['sample','GSM254699'],['sample','GSM254700'],['sample','GSM254701'],['sample','GSM254702'],['sample','GSM254703'],['sample','GSM254704'],
		 ['sample','GSM254705'],['sample','GSM254706'],['sample','GSM254707'],['sample','GSM254708'],['sample','GSM254709'],['sample','GSM254710'],
		 ['sample','GSM254711'],['sample','GSM254712'],['sample','GSM254713'],['sample','GSM254714'],['sample','GSM254715'],['sample','GSM254716'],
		 ['sample','GSM254717'],['sample','GSM254718'],['sample','GSM254719'],['sample','GSM254720'],['sample','GSM254721'],['sample','GSM254722'],
		 ['sample','GSM254723'],['sample','GSM254724'],['sample','GSM254725'],['sample','GSM254726'],['sample','GSM254727'],['sample','GSM254728'],
		 ['sample','GSM254729'],['sample','GSM254730'],['sample','GSM254731']];

    my $i=0;
    while (my $record=$parser->next) {
	my ($class,$geo_id)=@{$classes->[$i]};
	is (ref $record, $class, "$i: got $class");
	is ($record->{geo_id}, $geo_id, "$i: got ".$record->{geo_id});
	$i++;
    }

    is ($i-1, 109, "got 109 record");
}

main(@ARGV);

