#!/usr/bin/env perl 

#
# build the datasets and dataset_subsets dbs from the .soft files in GEO/data/datasets directory
# also build the word2freq database.
#
# Running this script with the -rebuild flag set (which is the DEFAULT) will cause 
# ALL PREVIOUS DATA IN THE  DATASETS AND DATASET_SUBSETS COLLECTIONS TO BE DELETED!
#
# It also modifies the series->{dataset_ids} field.
# It also adds to the word2geo table.
#
# Should maybe be called "parse_dataset_soft.pl"
#

use strict;
use warnings;
use Carp;
use Data::Dumper;
use MongoDB;
use FileHandle;
use File::Spec;

use lib "$ENV{HOME}/Dropbox/sandbox/perl";
use lib "$ENV{HOME}/Dropbox/sandbox/perl/PhonyBone";
use Options;
use PhonyBone::FileUtilities qw(dir_files warnf dief);
use PhonyBone::ListUtilities qw(in_list);

use FindBin;
use lib "$FindBin::Bin/../lib";
use ParseSoft;

BEGIN: {
  Options::use(qw(d q v h fuse=i rebuild=i s2ds db_name=s suffix=s));
    Options::useDefaults(fuse => -1, db_name=>'geo', rebuild=>1, suffix=>'.header');
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

# Globals:
my $connection;			# connection to mongo db
my $db;				# dataset within above (numerous collections accessed)
my $stats={};

sub main {
    my $mongos=get_mongos();
    my $soft_dir='/proj/price1/vcassen/trends/data/GEO/datasets';

    # rebuild the datasets and dataset_subsets dbs:
    rebuild($mongos, $soft_dir) if $options{rebuild};

    # find all keys:
    report_keys($mongos) if $options{find_keys};

    # make hash of subsets: k=sample, v=[array of datasets]
    # I'm curious about overlap
    find_subsets($mongos) if $options{s2ds};
}

sub get_mongo {
    my ($db_name, $coll_name)=@_;
    $connection||=MongoDB::Connection->new;
    $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $collection;
}

# return a hash[ref] of the mongo collections of interest
sub get_mongos {
    my %collections;

    $collections{dataset}=get_mongo($options{db_name},'datasets');
    $collections{dataset}->ensure_index({geo_id=>1}, {unique=>1});
    $collections{dataset}->remove() if $options{rebuild}; # wipe clean

    $collections{subset}=get_mongo($options{db_name},'dataset_subsets');
    $collections{subset}->ensure_index({geo_id=>1}, {unique=>1});
    $collections{subset}->remove() if $options{rebuild}; # wipe clean

    $collections{sample}=get_mongo($options{db_name},'samples');
    $collections{sample}->ensure_index({geo_id=>1}, {unique=>1});
    $collections{sample}->remove() if $options{rebuild}; # wipe clean
    $collections{datatable}=$collections{sample};

    $collections{series}=get_mongo($options{db_name},'series');
    $collections{series}->ensure_index({geo_id=>1}, {unique=>1});

    $collections{word2geo}=get_mongo($options{db_name},'word2geo');
    $collections{word2geo}->ensure_index({word=>1, geo_id=>1}, {unique=>1}); # wish I had done this earlier
    wantarray? %collections : \%collections;
}


########################################################################

sub rebuild {
    my ($mongos, $soft_dir)=@_;
    my $fuse=$options{fuse};

    # iterate through all .soft files
    my $suffix=$options{suffix};
    my @files=dir_files($soft_dir, qr/$suffix$/); # parse ALL the files!
    foreach my $filename (@files) {
	warn "$filename\n" unless $options{q};
	my $p=ParseSoft->new("$soft_dir/$filename");
	my $records=$p->parse;
	foreach my $r (@$records) {
	    my $class=ref $r;
	    next if $class eq 'database'; # boooooorinnnng
	    insert($r, $mongos);
	}
	$stats->{n_files}++;
	last if --$fuse==0;	# debugging
    }
    warn "Stats: ",Dumper($stats);
}

sub insert {
    my ($record, $mongos)=@_;
    my $class=ref $record;
    my $mongo=$mongos->{$class} or return;
    $class eq 'dataset' and return insert_dataset($record, $mongos);
    $class eq 'subset' and return insert_subset($record, $mongos);
    $class eq 'datatable' and return insert_datatable($record, $mongos);
    confess "not supposed to get here: unknown class is $class";
}

sub insert_dataset {
    my ($dataset, $mongos)=@_;
    dief "no geo_id in %s", Dumper($dataset) unless $dataset->{geo_id};
    delete $dataset->{dataset};	# delete label telling us it's a dataset

    warnf("inserting dataset %s\n", $dataset->{geo_id}) if $ENV{DEBUG};
    eval {
	my $record=$mongos->{dataset}->insert($dataset, {safe=>1});
	warnf("%s: record is %s", $dataset->{geo_id}, Dumper($record)) if $ENV{DEBUG};
    };
    if ($@) {
	warnf "Couldn't insert: $@\n%s", Dumper($dataset);
	return;
    }

    # tie the dataset's series back to the dataset via an 'upsert':
    my $series=$mongos->{series}->find_one({geo_id=>$dataset->{reference_series}}) || {geo_id=>$dataset->{reference_series}, dataset_ids=>[]};
    if (defined $series->{dataset_id}) {
	if ($series->{dataset_id} ne $dataset->{geo_id}) {
	    push @{$series->{dataset_ids}}, $series->{dataset_id};
	}
	delete $series->{dataset_id};
    }
    $series->{dataset_ids}||=[];
    if (!in_list($series->{dataset_ids}, $dataset->{geo_id})) {
	if (scalar @{$series->{dataset_ids}} > 0) {
	    warnf "multiple datasets for series %s: %s, %s\n", $series->{geo_id}, $series->{dataset_id}, $dataset->{geo_id};
	    $stats->{n_multis}++;
	}
	push @{$series->{dataset_ids}},$dataset->{geo_id};
	$mongos->{series}->update({geo_id=>$series->{geo_id}}, $series, {upsert=>1});
	warnf("updating %s->%s\n", $dataset->{reference_series}, $dataset->{geo_id}) if $ENV{DEBUG};
    }

    # add to the word2geo:
    my @words=split(/\s+/, $dataset->{title});
    push @words, split(/\s+/, $dataset->{description});
    foreach my $word (@words) {
	$word=~s/[^\w\d_]//g;
	$mongos->{word2geo}->insert({word=>$word, geo_id=>$dataset->{geo_id}});
	$stats->{n_words}++;
	warnf("inserting %s->%s\n", $word, $dataset->{geo_id}) if $ENV{DEBUG};
    }
    $stats->{n_datasets}++;
}

sub insert_subset {
    my ($subset, $mongos)=@_;
    delete $subset->{subset};	# yes, we know.  It's a subset.  Thank you.
    dief "no geo_id in %s", Dumper($subset) unless $subset->{geo_id};

    $mongos->{subset}->insert($subset, {safe=>1});
    warnf("inserting %s\n", $subset->{geo_id}) if $ENV{DEBUG};
    
    # tie samples to datasets:
    foreach my $sample_id (split(/[\s,]/, $subset->{sample_id})) {
	my $sample=$mongos->{sample}->find_one({geo_id=>$sample_id}) || {geo_id=>$sample_id};
	$sample->{dataset_id}=$subset->{dataset_id};
	$mongos->{sample}->update({geo_id=>$sample_id}, $sample, {upsert=>1});
	warnf("updating %s->%s\n", $sample_id, $subset->{dataset_id}) if $ENV{DEBUG};
	$stats->{n_samples}++;
    }

    # add to the word2geo:
    my @words=split(/\s+/, $subset->{description});
    foreach my $word (@words) {
	$word=~s/[^\w\d_]//g;
	$mongos->{word2geo}->insert({word=>$word, geo_id=>$subset->{geo_id}});
	$stats->{n_words}++;
	warnf("inserting %s->%s\n", $word, $subset->{geo_id}) if $ENV{DEBUG};
    }
    $stats->{n_subsets}++;
}


sub insert_datatable {		# really only inserting the table header values:
    my ($datatable, $mongos)=@_;
    foreach my $pair (@{$datatable->{header}}) {
	my ($gsm, $header)=@$pair;
	next unless $gsm=~/^GSM\d+/;
	my $sample=$mongos->{sample}->find_one({geo_id=>$gsm}) || {geo_id=>$gsm};
	$sample->{description}=$header;
	my $report=$mongos->{sample}->update({geo_id=>$gsm}, $sample, {upsert=>1, safe=>1});
    }
}

########################################################################

# find all the top-level keys of a collection by iteration
# (as opposed to map-reduce methods)
# return a hash[ref]: k=found key, v={count=>$n, scalar=>boolean}
# where key count is the number of times it appears in the collection
#       key scalar indicates whether the document element is a simple scalar or not
sub find_keys {
    my ($collection)=@_;
    my $cur=$collection->find();
    my %keys;

    while ($cur->has_next) {
	my $doc=$cur->next;
	while (my ($k,$v)=each %$doc) {
	    my $hashlette=$keys{$k} || {};
	    $hashlette->{count}++;
	    $hashlette->{scalar}=ref $v? 0:1;
	    $keys{$k}=$hashlette;
	}
    }
    wantarray? %keys:\%keys;
}

########################################################################

# use the subsets collection to map samples back to their datasets.
# Return a hash[ref]: k=sample_id, v=[array of dataset ids]
sub find_sample2datasets {
    my ($mongos)=@_;
    my $subset_collection=$mongos->{SUBSET};
    my %sample2datasets;
    my @subsets=$subset_collection->find->all;
    foreach my $subset (@subsets) {
	my $dataset_id=$subset->{geo_id};
	$dataset_id=~s/_\d+$//;
	foreach my $sample_id (split(/[,\s]+/,$subset->{sample_id})) { # should be {sample_ids} in db, but it's not
	    push @{$sample2datasets{$sample_id}}, $dataset_id;
	}
    }
    wantarray? %sample2datasets:\%sample2datasets;
}

########################################################################
sub report_keys {
    my ($mongos)=@_;
    foreach my $collection (keys %$mongos) {
	print "Keys for $collection:\n";
	my $keys=find_keys($mongos->{$collection});
	foreach my $key (sort keys %$keys) {
	    printf("%-25s\tcount=%d\tscalar=%s\n", $key, $keys->{$key}->{count}, $keys->{$key}->{scalar});
	}
    }    
}

########################################################################

# find and print subsets
sub find_subsets {
    my ($mongos)=@_;
    my $sample2datasets=find_sample2datasets($mongos);
    
    # find avg # of datasets/sample:
    my $n_datasets=0;
    do {$n_datasets+=scalar @{$sample2datasets->{$_}}} for keys %$sample2datasets;
    my $n_samples=scalar keys %$sample2datasets;
    printf "datasets/sample: %.3f\n", $n_datasets/$n_samples;
}

main(@ARGV);


