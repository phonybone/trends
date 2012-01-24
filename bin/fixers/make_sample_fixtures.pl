#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use FindBin;
 
use lib "$FindBin::Bin/../../lib";
use GEO::Sample;

my $probe_ids=['1007_s_at','1053_at','117_at','121_at','1255_g_at','1294_at','1316_at','1320_at','1405_i_at','1431_at','1438_at','1487_at','1494_f_at','1598_g_at','160020_at','1729_at'];
my $gene_ids=['DDR1','RFC2','HSPA6','PAX8','GUCA1A','UBA7','THRA','PTPN21','CCL5','CYP2E1','EPHB3','ESRRA','CYP2A6','GAS6','MMP14','TRADD'];


my $probe_header=<<"HEADER";
Affymetrix Probeset ID,MAS5.0 Scaled 100 generated expression value,P-Value that indicates the significance level of the detection call
ID_REF,VALUE,DETECTION,P-VALUE
HEADER

my $series_title='Gene expression signature of cigarette smoking and its role in lung adenocarcinoma development and survival';

BEGIN: {
  Options::use(qw(d q v h fuse=i n_samples|n=i));
    Options::useDefaults(fuse => -1, n_samples=>10);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $series_id='GSE001';
    my $series=make_series($series_id);

    for my $i (1..$options{n_samples}) {
	my $data=make_data($probe_ids, $gene_ids, 2000.0, 1.0);
	my $sample_id=sprintf("GSM%04d", $i);
	write_sample_data($sample_id, 'probe', $probe_ids, $probe_header, $data);
	write_sample_data($sample_id, 'gene', $gene_ids, '', $data);
    }
}

sub make_series {
    my ($series_id)=@_;
    my $series=new GEO::Series($series_id);
    $series->title($series_title);
    my @sample_ids=map {sprintf("GSM%04d", $_)} 1..$options{n_samples};
    $series->{sample_id}=\@sample_ids;
    $series->update({upsert=>1});
    warn "$series_id updated\n";
    $series;
}


sub make_data {
    my ($probe_ids, $gene_ids, $r1, $r2)=@_;
    my $data={};
    my $n_genes=@$gene_ids;
    foreach my $i (0..$n_genes-1) {
	my $v1=rand($r1);
	my $v2=rand($r2);
	$data->{$probe_ids->[$i]}=[$probe_ids->[$i], $v1, $v2];
	$data->{$gene_ids->[$i]}=[$gene_ids->[$i], $v1];
    }
    $data;
}


sub write_sample_data {
    my ($sample_id, $id_type, $id_list, $header, $data)=@_;
    my $sample=GEO::Sample->new($sample_id);
    $sample->update({upsert=>1});

    my $dst_file=$id_type eq 'gene'? $sample->data_file : $sample->table_data_file;
    open(OUTPUT, ">$dst_file") or die "Can't open $dst_file for writing: $!\n";
    print OUTPUT $header if $header;
    for my $id (@$id_list) {
	print OUTPUT join("\t", @{$data->{$id}}), "\n";
    }
    close OUTPUT;
    warn "$dst_file written\n";
    
}

main(@ARGV);

