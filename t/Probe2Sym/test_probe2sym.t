#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use IO::Handle;
use Data::Babel::Client;

use Test::More qw(no_plan);
use PhonyBone::FileUtilities qw(warnf);

use FindBin qw($Bin);
use Cwd 'abs_path';
use lib abs_path("$Bin/../../lib");
our $class='Probe2Sym';

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class) or BAIL_OUT("$class has compile issues, quitting");
    my $p2s=$class->new;
    warnf "unlinking %s\n", $p2s->cache_path;
    unlink $p2s->cache_path if -r $p2s->cache_path;
    warn "getting table";
    my $table=$p2s->p2s;
    warn "got table";
    cmp_ok(ref $table, 'eq', 'HASH', "got HASH table");
    
    ok(-r $p2s->cache_path, sprintf "%s cached", $p2s->cache_path);
    my $p2s2=$class->new;	# get another, should use cache'd data
    cmp_ok(ref $p2s2->p2s, 'eq', 'HASH', "got HASH table");

    my @probes=qw(162028_f_at 1424023_at 97093_at 160645_at 223928_s_at);
    cmp_ok($p2s->p2s->{$_}, 'eq', $p2s2->p2s->{$_}, sprintf("got %s->%s", $_, $p2s->p2s->{$_})) for @probes;
    
}

main(@ARGV);

