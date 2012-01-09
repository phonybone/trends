#!/usr/bin/env perl 
use strict;
use warnings;
use Carp;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;

use Options;
use PhonyBone::FileUtilities qw(warnf dief);

BEGIN: {
  Options::use(qw(d q v h fuse=i base_url=s db=s retmax=i));
    Options::useDefaults(fuse => -1,
			 retmax=>20,
			 db=>'gds',
			 term=>'GSE[ETYP]',
			 search_url=>'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi',
			 summary_url=>'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi',
			 );
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    my $ua=LWP::UserAgent->new;
    my ($ids, $web_env, $query_key)=search($ua);
    my $stuff=summary($ua, $web_env, $query_key);
    
}

sub search {
    my ($ua)=@_;

    my $url=sprintf("%s?db=%s&term=%s&retmax=%d&usehistory=y",$options{search_url}, $options{db}, $options{term}, $options{retmax});
    warn "fetching $url\n";

    my $req=POST ($url);
    my $res=$ua->request($req);
    warn Dumper($res);
    my $content=$res->content;	# should check for errors, but whatevs

    # extract WebEnv key, ID list:
    $content=~/<WebEnv>(.*)<\/WebEnv>/ms;
    my $web_env=$1;
#    warn "web_env is $web_env\n";

    # query key:
    $content=~/<QueryKey>(\d+)<\/QueryKey>/ms;
    my $query_key=$1;

    # ids:
    my @ids;
    while ($content=~/<Id>(.*?)<\/Id>/msg) {
	push @ids, $1;
    }
#    warnf "got %d ids\n", scalar @ids;
#    warn Dumper(\@ids);
    (\@ids, $web_env, $query_key);
}

sub summary {
    my ($ua, $web_env, $query_key)=@_;

    my $url=sprintf("%s?db=%s&query_key=%d&WebEnv=%s&retmax=%d&retmode=%s", 
		    $options{summary_url}, $options{db}, $query_key, $web_env, $options{retmax}, 'soft');
    warn "fetching $url\n";
    my $req=POST $url;
    my $res=$ua->request($req);
    
    my $content=$res->content;
    warn Dumper($content);
}

main(@ARGV);

