#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
 
use Options;			# PhonyBone::Options, sorta

use FindBin qw($Bin);
use Cwd qw(abs_path);
use lib abs_path("$Bin/../lib");

use GSMs2CSV;
use PhonyBone::FileUtilities qw(spitString);

BEGIN: {
  Options::use(qw(d q v h fuse=i out_filename=s));
  Options::required(qw(out_filename));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my @gsms=@_;
    @gsms>0 or die usage(qw(gsms));

    my $g2c=new GSMs2CSV;
    $g2c->add_gsm($_) for @gsms;
    my $table=$g2c->table;
    spitString($table->as_str(), $options{out_filename});
    warn $options{out_filename}, " written\n";
    exit 0;
}

main(@ARGV);

