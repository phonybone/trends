#!/usr/bin/env perl 
use strict;
use warnings;

#
# Assemble a 2D matrix of gene expression values from GEO samples that have phenotypes
# assigned to them.
# Currently just prints to STDOUT, but todo: add output filename to %options.
#

use Carp;
use Data::Dumper;
use Options;
use PhonyBone::FileUtilities qw(warnf dief);
use FindBin;

use lib "$FindBin::Bin/../lib";
use GEO;

BEGIN: {
  Options::use(qw(d q v h fuse=i phenos|p=s gsms=s gses=s write_matrix=i data_src=s));
    Options::useDefaults(fuse => -1,
			 write_matrix=>1,
			 phenos=>[],
			 gsms=>[],
			 gses=>[],
			 data_src=>'gene',
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my @records=get_pheno_records();
    warnf "got %d pheno records\n", scalar @records;

    my $matrix=create_matrix(\@records);
    warnf "matrix: %d rows\n", scalar @$matrix;
    write_matrix($matrix) if $options{write_matrix};
}

sub create_matrix {
    my ($records)=@_;
    warn "creating matrix...\n";
    my $matrix=[];

    my $fuse=$options{fuse};
    my $n=1;
    foreach my $record (@$records) {
	 warnf "%4d. %s : %s\n", $n++, $record->{geo_id}, $record->{phenotype};
	 my $sample=GEO::Sample->new(%$record);
	 my $data_vector={geo_id=>$sample->geo_id, 
			  phenotype=>$sample->phenotype, 
			  expr=>$sample->as_vector_hash({data_src=>$options{data_src}})};
	 push @$matrix, $data_vector;
	 last if --$fuse==0;
     }

    # or,
#    my @matrix=map {GEO::Series->new(%$_)->data_vector} get_pheno_records();

    $matrix;
}


# Return GEO records based on phenotype, sample, or series.  If none
# of these are specified, return *all* the phenotype "records".
sub get_pheno_records {
    my @records=get_requested_records('phenos','phenotype');
    @records=   get_requested_records('gsms', 'geo_id') unless @records;
    @records=   get_gse_records() unless @records;
    @records=   get_all_pheno_records() unless @records;

    warnf "before grep: %d records\n", scalar @records if $ENV{DEBUG};
    @records=grep {$_->{phenotype}} @records; # only keep records that define a phenotype
    warnf "after grep: %d records\n", scalar @records if $ENV{DEBUG};
    @records=sort by_pheno_by_geo_id @records;

    wantarray? @records:\@records;
}


sub get_gse_records {
    warn "looking for gse records...\n" if $ENV{DEBUG};
    my @records=();
    my $gses=Options::file_or_list('gses');
    foreach my $gse (@$gses) {
	my @r2;
	my $series=GEO::Series->new($gse);
	my $sample_ids=$series->sample_ids or next;
	warnf "%s: got %d samples\n", $series->geo_id, scalar @$sample_ids;
	foreach my $sample_id (@{$sample_ids}) {
	    push @r2, GEO::Sample->get_mongo_record($sample_id);
	}
	warnf "$gse records: %d samples before grep\n", scalar @r2 if $ENV{DEBUG};
	@r2=grep {$_->{phenotype}} @r2;
	warnf "$gse records: %d samples after grep\n", scalar @r2 if $ENV{DEBUG};
	push @records, @r2 if @r2;
    }
    wantarray? @records:\@records;
}

sub get_requested_records {
    my ($opt, $field)=@_;
    my $list=Options::file_or_list($opt) or return undef;
    warn "looking for $opt records...\n" if $ENV{DEBUG};
    my @records;
    foreach my $l (@$list) {
	my $records=GEO::Sample->get_mongo_records({$field=>$l});
	warnf "got %d records for %s=%s\n", scalar @$records, $field, $l if $ENV{DEBUG};
	push @records, @$records if $records;
    }
    wantarray? @records:\@records;
}

sub get_all_pheno_records {
    my @records=GEO::Sample->get_mongo_records({phenotype => {'$ne'=>undef}});
    wantarray? @records:\@records;
}

sub by_pheno_by_geo_id($$) {
    my ($r1,$r2)=@_;
    return ($r1->{phenotype} cmp $r2->{phenotype}) || GEO::by_geo_id($r1->{geo_id},$r2->{geo_id});
}

# print the matrix to STDOUT; tsv format (fixme: make an option)
sub write_matrix {
    warn "writing matrix...\n";
    my ($matrix)=@_;
    
    # gather union of all probe_ids:
    my %probe_ids;
    foreach my $col (@$matrix) {
	foreach my $probe_id (keys %{$col->{expr}}) {
	    $probe_ids{$probe_id}=1;
	}
    }
    warnf "matrix: %d x %d\n", scalar keys %probe_ids, scalar @$matrix;

    # print matrix: header
    # fixme: still need ID_REF, <_____> 
    my @headers = map {join(':',$_->{geo_id}, $_->{phenotype})} @$matrix;
    print join("\t", @headers), "\n";

    my $n=0;
    foreach my $probe_id (sort keys %probe_ids) {
	warnf "%4d. %s\n", ++$n, $probe_id;
	my @exprs=($probe_id);
	foreach my $col (@$matrix) {
	    my $expr=$col->{expr}->{$probe_id} || '-';
	    push @exprs, $expr;
	}
	print join("\t", @exprs), "\n";
    }
}

main(@ARGV);

