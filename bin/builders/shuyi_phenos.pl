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
			 src_dir=>"$ENV{TRENDS_HOME}/shuyi",
			 db_name=>'geo',
	);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO->db_name($options{db_name});
}

# Don't actually use these in the db; we'd have to have codes for every phenotype that
# ever came along, and we'd have to ensure that they're different, etc.
# But, yes, these will be hard to search on...
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
    warnf "$0 ", join(' ',@_), "\n" if $ENV{DEBUG};
    warnf "writing to %s\n", GEO::Sample->mongo_coords;
    $stats->{db_name}=GEO::Sample->mongo_coords;
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
		$@=~s/\n.*/\n/gsm;
		warn $@;
		$stats->{no_class}++;
		next;
	    }
	    
	    push @{$sample->phenotypes}, $pheno;
	    warnf "%s -> %s\n", $sample->geo_id, $pheno;
	    $sample->save unless $options{n};
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

