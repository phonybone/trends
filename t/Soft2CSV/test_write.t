#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../../lib");
our $class='Soft2CSV';

BEGIN: {
  Options::use(qw(d q v h fuse=i gse=s));
    Options::useDefaults(fuse => -1,
			 gse=>'GSE10072',
	);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


# Call $soft2csv->write
# Check

sub main {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    my $in_filename=new GEO::Series($options{gse})->soft_path;
    my $soft2csv=$class->new($in_filename);
    isa_ok($soft2csv, $class, "got a $class");

    unlink $soft2csv->out_filename if -e $soft2csv->out_filename;
    cmp_ok($soft2csv->write, 'eq', $soft2csv->out_filename, $soft2csv->out_filename);
    ok( -r $soft2csv->out_filename);

    # Add checks for correctness of file contents:
}

main(@ARGV);

