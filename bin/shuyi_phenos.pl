#!/usr/bin/env perl 
use strict;
use warnings;

#
# Assign a phenotype to each GSM in Shuyi's dataset.  
# Record that phenotype in the db.
# Record and report stats.
#

use Carp;
use Data::Dumper;
use FindBin;
use Options;
use PhonyBone::FileUtilities qw(warnf dief file_lines dir_files);

use lib "$FindBin::Bin/../lib";
use GEO;

BEGIN: {
  Options::use(qw(d q v h n fuse=i src_dir=s db_name=s));
    Options::useDefaults(fuse => -1, 
			 src_dir=>'/proj/price1/vcassen/trends/shuyi',
			 db_name=>'geo',
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO->db_name($options{db_name});
    warnf "writing to %s\n", $options{db_name};
}

my %codes=(
	   ADC=>'adenocarcinoma',
	   SCC=>'squamous cell carcinoma',
	   LCLC=>'large cell lung carcinoma',
	   AST=>'asthma',
	   COPD=>'chronic obstructive pulmonary disease',
	   NORM=>'normal',
	   );

my $stats={};

sub main {
    my @files=get_files();

    foreach my $file (@files) {
	my $pheno=get_pheno($file) or warn "no pheno for $file", next;
	warnf "\n%s: pheno=%s\n", $file, $pheno;

	my @sample_ids=file_lines(join('/', $options{src_dir}, $file));
	foreach my $sample_id (@sample_ids) {
	    chomp $sample_id;
	    $stats->{total_samples}++;
	    my $sample;
	    eval { $sample=GEO->factory($sample_id) };
	    if ($@) {
		warn $@;
		$stats->{no_class}++;
		next;
	    }
	    
	    unless ($sample->_id) {
		warnf "$sample_id: record not found\n";
		$stats->{not_found}++; # won't update anyway without upsert
		next;
	    }

	    $sample->phenotype($pheno);
	    warnf "%s -> %s\n", $sample->geo_id, $pheno;
	    $sample->update unless $options{n};
	    $stats->{n_updated}++;
	    $stats->{$pheno}++;
	}
    }
    warn "Stats:\n", Dumper($stats);
}

sub get_files {
    dir_files($options{src_dir}, qr/\.tsv$/);
}

sub get_pheno {
    my ($filename)=@_;
    $filename=~/_[A-Z]+/ or die "bad filename: $filename";
    $codes{substr($&,1)};		# skip leading '_'
}

main(@ARGV);

