#!/usr/bin/perl

#
# Fix two bugs in parse_series.pl where:
# 1. series->{samples} field was left empy
# 2. raw_samples->{series_id} was left empty
# 


use strict;
use warnings;
use Carp;

use File::Spec qw(catfile);
use MongoDB;

use lib "$ENV{HOME}/Dropbox/sandbox/perl";
use lib "$ENV{HOME}/Dropbox/sandbox/perl/PhonyBone";
use Options;

our ($db, $connection);

BEGIN: {
  Options::use(qw(d q v h fuse=i no_clear rebuild overwrite_data delay=i dst_dir=s overwrite ftp_link=s ftp_base=s keep_tars filter_gses=s));
    Options::useDefaults(fuse => -1, delay => 5,
			 base_dir=>'/proj/price1/vcassen/trends/data/GEO',
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}

sub main() {
    my $mongos=get_mongos();

    my @series_dirs=get_series_dirs();
    my $n_series=0;
    my $n_samples=0;

    my $fuse=$options{fuse};
    foreach my $series_dir (@series_dirs) {
	# get list of files in $series_dir that end in .gz and have a geo_id in the filename:
	my $sample_files=[grep {get_geo_id($_)} get_matching_files($series_dir, qr/\.gz$/)];
#	warn "no sample files for $series_dir\n" unless scalar @$sample_files;
	next unless @$sample_files;

	# update series record:
	my $series_gid=get_geo_id($series_dir) or die "no geo_id in $series_dir";
	my $series_rec=$mongos->{series}->find_one({geo_id=>$series_gid}) or die "no series record for '$series_gid'";
	my $sample_ids=[map {get_geo_id($_)} @$sample_files];
	$series_rec->{samples}=$sample_ids; # add sample files to record
	$mongos->{series}->save($series_rec);
	$n_series++;

	# update raw_sample records:
	foreach my $sample_file (@$sample_files) {
	    my $sample_id=get_geo_id($sample_file) or die "no geo_id in $sample_file";
	    my $sample=$mongos->{raw_samples}->find_one({geo_id=>$sample_id}) or die "no raw_sample '$sample_id'";
	    $sample->{series_id}=$series_gid;
	    $sample->{path}=join('/', $series_dir, $sample_file);
	    $mongos->{raw_samples}->save($sample);
	    $n_samples++;
	}

	last if --$fuse==0;
    }
    warn "$n_series series updated\n";
    warn "$n_samples samples updated\n";
}

sub get_mongo {
    my ($db_name, $coll_name)=@_;
    $connection=MongoDB::Connection->new;
    $db=$connection->$db_name;
    my $collection=$db->$coll_name;
    $collection;
}

# return a hash[ref] of the mongo collections of interest
sub get_mongos {
    my %collections;
    my $db_name=$ENV{DEBUG}? 'geo_test' : 'geo';
    $collections{series}=get_mongo($db_name,'series');
    $collections{series}->ensure_index({geo_id=>1},{unique=>1});

    $collections{raw_samples}=get_mongo($db_name,'raw_samples');
    $collections{raw_samples}->ensure_index({geo_id=>1},{unique=>1});
    wantarray? %collections : \%collections;
}

# return a list of all series dirs:
sub get_series_dirs {
    my $series_dir=File::Spec->catpath(undef, $options{base_dir}, 'series');
    my @series_dirs=map {File::Spec->catpath(undef, "$options{base_dir}/series", $_)} get_matching_files($series_dir, qr/^GSE/);
    wantarray? @series_dirs:\@series_dirs;
}

# extract a geo_id from a string (eg filename)
# returns undef if no geo_id found in string
sub get_geo_id {
    my ($thing)=@_;
    $thing=~/(GSM|GSE|GDS)(\d+)/ or return undef;
#    $thing=~/(GSM|GSE|GDS)(\d+)/ or confess "no geo_id in $thing";
    "$1$2";
}

# return all the files (incl subdirectories) in a directory whose name matches a regex:
# files do not contain $dir
sub get_matching_files {
    my ($dir, $regex)=@_;
    opendir (DIR,$dir) or die "Can't read dir '$dir': $!\n";
    my @files=grep /$regex/, readdir DIR;
    close DIR;
    wantarray? @files:\@files;
}

main();
