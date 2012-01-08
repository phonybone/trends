#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use Devel::Size qw(size total_size);
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../../..";
use ParseSoft;

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
    GEO->testing(1);

    my $gpl8300_file="$FindBin::Bin/GPL8300.soft";
    my $p=ParseSoft->new($gpl8300_file);
    my $records=$p->parse;
    is(scalar @$records, 1, "got one record");
    my $record=$records->[0];

    delete $record->{__table};

    warnf "total_size: %d\n", total_size($record);
    while (my ($k,$v)=each %$record) {
	warnf "%s: size=%d\n", $k, total_size($v);
#	warn Dumper($record->{$k});
    }

}

main(@ARGV);

