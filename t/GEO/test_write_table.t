#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);
use Text::CSV;
use PhonyBone::FileUtilities qw(warnf);

use FindBin;
use lib "$FindBin::Bin/../..";

our $class='GEO';


BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);
    test_data_table_file();
    test_write_table();
}

sub test_data_table_file {
    my $geo_id='GSE1000';
    my $series=$class->factory($geo_id);
    my $tailpath=join('/', $series->subdir, $geo_id, "$geo_id.table.data");
    like($series->data_table_file, qr/$tailpath/, "got data_table_file for $geo_id");

    $geo_id='GPL96';
    my $platform=$class->factory($geo_id);
    $tailpath=join('/', $platform->subdir, $geo_id, "$geo_id.table.data");
    like($platform->data_table_file, qr/$tailpath/, "got data_table_file for $geo_id");

    $geo_id='GSM100826';
    my $sample=$class->factory($geo_id);
    #warn "sample $geo_id: dtf is ", $sample->data_table_file;
    $tailpath=join('/', $sample->subdir, 'GSM100', "$geo_id.table.data");
    like($sample->data_table_file, qr/$tailpath/, "got data_table_file for $geo_id");

    
}

sub test_write_table {
    my $geo_id='GSE1000';
    my $series=$class->factory($geo_id);
    my $table={header=>[['h1','desc1'],['h2','desc2']],
	       data=>[[3,2],[29,65],[2,6]]};
    my $dest_file="$FindBin::Bin/$geo_id.table";
    $series->write_table($table, $dest_file);

    my $csv=Text::CSV->new({binary=>1});
    my $fh;
    ok (open($fh, "<", $dest_file), "opened $dest_file");

    my $row=$csv->getline($fh);
    is_deeply($row, ['desc1', 'desc2']);

    $row=$csv->getline($fh);
    is_deeply($row, [3,2]);

    $row=$csv->getline($fh);
    is_deeply($row, [29,65]);

    $row=$csv->getline($fh);
    is_deeply($row, [2,6]);
    $fh->close;
    
}



main(@ARGV);

