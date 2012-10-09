#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf spitString);

use Test::More qw(no_plan);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../../lib");
our $class='GSMs2CSV';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1,
			 out_filename=>"$Bin/gsms4.csv",
	);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    my $g2c=$class->new();
    isa_ok($g2c, $class, "got a $class");

    my @gsms=qw(GSM21832 GSM19135 GSM9514 GSM42864);
    $g2c->add_gsm($_) for @gsms;
    my $table=$g2c->table;

    isa_ok($table, 'PhonyBone::Hash2D', sprintf("got table HASH (actually: %s)", ref $table));
    my @expected_headers=('IDENTIFIER');
    push @expected_headers, @gsms;

    is_deeply([@{$table->x_axis}], \@expected_headers, "got gsms headers");
    cmp_ok($table->n_cols, '==', 5, '5 cols');
    cmp_ok($table->n_rows, '==', 14024, '14024 rows');

    spitString($table->as_str(include_headers=>1)."\n", $options{out_filename});
    warn $options{out_filename}, " written\n";
}

main(@ARGV);

