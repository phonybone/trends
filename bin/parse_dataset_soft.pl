#!/usr/bin/env perl 

#
# build the datasets and dataset_subsets dbs from the .soft files in GEO/data/datasets directory
# also build the word2freq database.
#
# Running this script with the -rebuild flag set (which is the DEFAULT) will cause 
# ALL PREVIOUS DATA IN THE  DATASETS AND DATASET_SUBSETS COLLECTIONS TO BE DELETED!
#
# It also modifies the series->{dataset_ids} field.
# It does NOT add to the word2geo table.
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
use PhonyBone::ListUtilities qw(in_list max);

use FindBin;
use lib "$FindBin::Bin/../lib";
use GEO;
use ParseSoft;

BEGIN: {
  Options::use(qw(d q v h fuse=i rebuild=i db_name=s suffix=s ignore_table=i 
		  dataset_dir=s
		  clear_datasets clear_subsets clear_samples clear_all
		  find_keys s2ds
));
    Options::useDefaults(fuse => -1, db_name=>'geo', rebuild=>1, suffix=>'.header',
			 dataset_dir=>"$ENV{TRENDS_HOME}/data/GEO/datasets");
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
    GEO->db_name($options{db_name});
    warnf "writing to %s\n", $options{db_name} if $ENV{DEBUG};
    $options{ignore_table}=1 if $options{suffix} eq '.header';
    if ($options{clear_all}) {
	$options{clear_datasets}=1;
	$options{clear_subsets}=1;
	$options{clear_samples}=1;
    }
}

# Globals:
my $connection;			# connection to mongo db
my $db;				# dataset within above (numerous collections accessed)
my $stats={};
my $mongos;

sub main {
    $mongos=get_mongos();
    my $soft_dir=$options{dataset_dir};

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
    if ($options{clear_datasets}) { # wipe clean
	$collections{dataset}->remove();
	warnf "removing all records from %s:%s\n", $options{db_name}, 'datasets';
    }

    $collections{subset}=get_mongo($options{db_name},'dataset_subsets');
    $collections{subset}->ensure_index({geo_id=>1}, {unique=>1});
    if ($options{clear_subsets}) { # wipe clean
	$collections{subset}->remove();
	warnf "removing all records from %s:%s\n", $options{db_name}, 'dataset_subsets';
    }

    $collections{sample}=get_mongo($options{db_name},'samples');
    $collections{sample}->ensure_index({geo_id=>1}, {unique=>1});
    if ($options{clear_samples}) { # wipe clean
	$collections{sample}->remove();
	warnf "removing all records from %s:%s\n", $options{db_name}, 'samples';
    }

    $collections{series}=get_mongo($options{db_name},'series');
    $collections{series}->ensure_index({geo_id=>1}, {unique=>1});

    wantarray? %collections : \%collections;
}


########################################################################

sub rebuild {
    my ($mongos, $soft_dir)=@_;
    my $fuse=$options{fuse};

    # iterate through all .soft files
    my $suffix=$options{suffix};
    my @files=dir_files($soft_dir, qr/$suffix$/); # parse ALL the files!
    warnf "got %d %s files under %s\n", scalar @files, $options{suffix}, $soft_dir if $ENV{DEBUG};
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

    # want to write data table?
    delete $record->{__table} if $options{suffix} eq '.header' || $options{ignore_table};
    write_table($record) if $record->{__table};

    # remove any other '_keys':
    foreach my $key (grep /^_/, keys %$record) {
	next if $key eq '__table'; # hack
	delete $record->{$key};
    }

    $class eq 'dataset' and return insert_dataset($record, $mongos);
    $class eq 'subset' and return insert_subset($record, $mongos);
    $class eq 'datatable' and return insert_datatable($record, $mongos);
    confess "not supposed to get here: unknown class is $class";
}

sub write_table {		# fixme: implement this
    my ($record)=@_;
}


sub delete_geo_id_keys {
    my ($geo)=@_;
    my $type=(split('::', lc ref $geo))[-1];
    my $regex=qr(^${type}_G\w\w\d+);
    my @sample_keys=grep /$regex/, keys %$geo;
    foreach my $key (@sample_keys) {
	delete $geo->{$key};
    }
}


sub insert_dataset {
    my ($dataset, $mongos)=@_;
    my $geo_id=$dataset->{geo_id} or dief "no geo_id in %s", Dumper($dataset);
    delete $dataset->{dataset};	# delete label telling us it's a dataset

    my $ds=GEO::Dataset->new($geo_id);
    $ds->hash_assign(%$dataset);
    delete_geo_id_keys($ds);
    $ds->update({upsert=>1});
    $stats->{datasets_updated}++;

    GEO::Series->new($dataset->{reference_series})->tie_to_geo($dataset->{geo_id}, 'dataset_ids');
#    tie_geo_to_geo($dataset->{reference_series}, $dataset, 'dataset_ids'); # to series to dataset
    $stats->{n_datasets}++;
}

sub insert_subset {
    my ($subset, $mongos)=@_;
    delete $subset->{subset};	# yes, we know.  It's a subset.  Thank you.

    # get subset object:
    my $geo_id=$subset->{geo_id} or confess "no 'geo_id' in ",Dumper($subset);
    my $ss=GEO::DatasetSubset->new($geo_id);
    $ss->hash_assign(%$subset);
    delete_geo_id_keys($ss);

    # remove $ss->{sample_id} and replace with $ss->{sample_ids}:
    my $sample_ids=$ss->{sample_id}; # csv list
    delete $ss->{sample_id};
    foreach my $sample_id (split(/[,\s]/, $sample_ids)) {
	$ss->append('sample_ids', $sample_id, {unique=>1});
    }

    # update $ss in db:
    $ss->update({upsert=>1});
    $stats->{n_subsets}++;
    warnf("inserting %s\n", $subset->{geo_id}) if $ENV{DEBUG};
    
    # tie samples to back to everything:
    my $dataset_id=$subset->{geo_id}; 
    $dataset_id=~s/_\d+$//;
    my $ds_rec=GEO::Dataset->get_mongo_record($dataset_id) || {};
    my $series_id=$ds_rec->{reference_series};
    foreach my $sample_id (split(/[\s,]/, $subset->{sample_id})) {
	my $sample=GEO::Sample->new($sample_id);
	$sample->tie_to_geo($subset, 'subset_ids');
	$sample->tie_to_geo($dataset_id, 'dataset_ids');
	$sample->tie_to_geo($series_id, 'series_ids') if $series_id;
    }


    # up the number of subsets in the dataset record:
    $geo_id=~/_\d+$/ or die "badly formed subset geo_id: $geo_id";
    my $nth_subset=substr($&,1);
    my $n_subsets=$ds_rec->{n_subsets} || 0;
    $n_subsets=max($n_subsets, $nth_subset);
    $ds_rec->{n_subsets}=$n_subsets;
    GEO::Dataset->mongo()->update({geo_id=>$dataset_id}, $ds_rec);
}



# really only inserting the table header values:
# assigns 
sub insert_datatable {		
    my ($datatable, $mongos)=@_;
    foreach my $pair (@{$datatable->{header}}) {
	my ($gsm, $header)=@$pair;
	next unless $gsm=~/^GSM\d+/;
	my $sample=$mongos->{sample}->find_one({geo_id=>$gsm}) || {geo_id=>$gsm};
	$sample->{description}=$header;	# fixme: what if description already exists from different dataset.soft file?
	my $report=$mongos->{sample}->update({geo_id=>$gsm}, $sample, {upsert=>1, safe=>1});
	if ($report->{n}==1) {
	    warn "Sample %s: description=%s\n", $gsm, $header unless $options{q};
	} else {
	    warnf "Sample %s: unable to update description (via header): '%s'\n", $gsm, $header; 
	}
    }
}

########################################################################
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


