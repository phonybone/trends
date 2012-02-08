#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use File::Basename;

# Want to copy all (?) samples to the fixtures directory, but only using
# certain probes
 
use Options;
use PhonyBone::FileUtilities qw(warnf dief);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO::Sample;

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $probes=['1053_at','117_at','121_at','1255_g_at','1316_at','1320_at','1405_i_at',
                '1431_at','1438_at','1487_at','1494_f_at','1598_g_at','160020_at','1729_at'];
    my $dst_dir=join('/',$ENV{TRENDS_HOME}, 't', 'fixtures', 'data', 'GEO', 'sample_data');
    my $records=GEO::Sample->get_mongo_records({}, {geo_id=>1});

    my $stats={};
    $stats->{total_samples}=scalar @$records;
    my $header=<<"    HEADER";
,X01K01501
ID_REF,VALUE
    HEADER
    
    my $fuse=$options{fuse};
    foreach my $record (@$records) {
	my $sample_id=$record->{geo_id} or dief "no sample_id in %s???", Dumper($record);
	my $sample=new GEO::Sample($sample_id);
	my $data;
	eval { $data=$sample->as_vector_hash };
	next if $@;

	my $subdir=substr($sample_id,0,6);
	my $dst_path=join('/', $dst_dir, $subdir, "${sample_id}.table.data");
	my $dst_subdir=dirname($dst_path);
	mkdir $dst_subdir unless -d $dst_subdir;

	open (DST, ">$dst_path") or die "Can't open $dst_path for writing: $!\n";
	print DST $header;
	foreach my $probe (@$probes) {
	    my $value=$data->{$probe} or next;
	    print DST join(',',$probe,$value), "\n";
	}
	close DST;
	warn "$dst_path written\n";
	$stats->{n_samples}++;
	last if --$fuse==0;
    }
    warn Dumper($stats);
}

main(@ARGV);

