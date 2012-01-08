#!/usr/bin/env perl 
#-*-perl-*-
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Options;
use Test::More qw(no_plan);

use FindBin;
use Cwd qw(abs_path);
use File::Spec;

use lib abs_path("$FindBin::Bin/../../../lib");

our $class='ParseSoft';
our $trends_dir=abs_path("$FindBin::Bin/../../.."); # can't use this in 'use lib' because it's not set until runtime

BEGIN: {
  Options::use(qw(d q v h fuse=i));
    Options::useDefaults(fuse => -1);
    Options::get();
    die Options::usage() if $options{h};
    $ENV{DEBUG} = 1 if $options{d};
}


sub main {
    require_ok($class);

    my $soft_file=File::Spec->catfile($trends_dir, qw(data GEO datasets GDS183.soft));
    my $parser=$class->new($soft_file);
    isa_ok($parser, $class, "got $class");
    my $soft_records=$parser->parse;

    my $header_file=File::Spec->catfile($trends_dir, qw(data GEO datasets GDS183.header));
    $parser->filename($header_file);
    my $header_records=$parser->parse;

    test_GDS183($soft_records, 1);
    test_GDS183($header_records, 0);

    is (scalar @$soft_records, scalar @$header_records, "got same number of records");
    # check every record except the data for sameness:
    for (my $i=0; $i<scalar @$soft_records -1; $i++) {
	my $sr=$soft_records->[$i];
	my $hr=$header_records->[$i];
	is_deeply($sr, $hr, "record $i the same");
    }
}

sub test_GDS183 {
    my ($records, $test_data)=@_;

    my @r2=@$records;
    is(scalar @$records, 9);

    my $record=shift @$records;
    isa_ok($record, 'database');
    is($record->{name}, "Gene Expression Omnibus (GEO)");
    is($record->{institute}, 'NCBI NLM NIH');
    is($record->{web_link}, 'http://www.ncbi.nlm.nih.gov/geo');
    is($record->{email}, 'geo@ncbi.nlm.nih.gov');
    is($record->{ref}, 'Nucleic Acids Res. 2005 Jan 1;33 Database Issue:D562-6');

    $record=shift @$records;
    isa_ok($record, 'dataset');
    is($record->{title}, 'Bladder tumor stage classification');
    is($record->{type}, 'Expression profiling by array');
    is($record->{pubmed_id}, '12469123');
    is($record->{platform}, 'GPL80');
    is($record->{platform_organism}, 'Homo sapiens');
    is($record->{platform_technology_type}, 'in situ oligonucleotide');
    is($record->{feature_count}, '7129');
    is($record->{sample_organism}, 'Homo sapiens');
    is($record->{sample_type}, 'RNA');
    is($record->{channel_count}, '1');
    is($record->{sample_count}, '40');
    is($record->{value_type}, 'count');
    is($record->{reference_series}, 'GSE89');
    is($record->{order}, 'none');
    is($record->{update_date}, 'Apr 09 2003');


    my $data_table=$record->{__table};
    is (ref $data_table, 'HASH');
    is(ref $data_table->{data}, 'ARRAY');
    is(ref $data_table->{header}, 'ARRAY');

    is_deeply($data_table->{header}, [
				      ['ID_REF','Platform reference identifier' ],
				      ['IDENTIFIER','identifier' ],
				      ['GSM2528','Bladder sample 880-1; src: tumour' ],
				      ['GSM2519','Bladder sample 625-1; src: tumour',], 
				      ['GSM2524','Bladder sample 812-1; src: tumour'],
				      ['GSM2525','Bladder sample 847-1; src: tumour' ],
				      ['GSM2529','Bladder sample 919-1; src: tumour' ],
				      ['GSM2539','Bladder sample 1134-1; src: tumour' ],
				      ['GSM2540','Bladder sample 1065-1; src: tumour' ],
				      ['GSM2541','Bladder sample 1269-1; src: tumour' ],
				      ['GSM2542','Bladder sample 1083-2; src: tumour' ],
				      ['GSM2543','Bladder sample 1238-1; src: tumour' ],
				      ['GSM2544','Bladder sample 1257-1; src: tumour' ],
				      ['GSM2510','Bladder sample 1117-1; src: tumour' ],
				      ['GSM2512','Bladder sample 1133-1; src: tumour' ],
				      ['GSM2506','Bladder sample 1044-1; src: tumour' ],
				      ['GSM2509','Bladder sample 1078-1; src: tumour' ],
				      ['GSM2515','Bladder sample 1178-1; src: tumour' ],
				      ['GSM2526','Bladder sample 875-1; src: tumour' ],
				      ['GSM2538','Bladder sample 1068-1; src: tumour' ],
				      ['GSM2513','Bladder sample 1164-1; src: tumour' ],
				      ['GSM2505','Bladder sample 1032-1; src: tumour' ],
				      ['GSM2521','Bladder sample 709_1; src: tumour' ],
				      ['GSM2530','Bladder sample 928_1; src: tumour' ],
				      ['GSM2531','Bladder sample 930_1; src: tumour' ],
				      ['GSM2532','Bladder sample 934-1; src: tumour' ],
				      ['GSM2533','Bladder sample 937-1; src: tumour' ],
				      ['GSM2536','Bladder sample 968_1; src: tumour' ],
				      ['GSM2507','Bladder sample 1062-2; src: tumour' ],
				      ['GSM2508','Bladder sample 1070-1; src: tumour' ],
				      ['GSM2511','Bladder sample 112-10; src: tumour' ],
				      ['GSM2514','Bladder sample 1166-1; src: tumour' ],
				      ['GSM2516','Bladder sample 1264-1; src: tumour' ],
				      ['GSM2517','Bladder sample 1330-1; src: tumour' ],
				      ['GSM2518','Bladder sample 320-7; src: tumour' ],
				      ['GSM2520','Bladder sample 669-7; src: tumour' ],
				      ['GSM2522','Bladder sample 716-2; src: tumour' ],
				      ['GSM2523','Bladder sample 747-7; src: tumour' ],
				      ['GSM2527','Bladder sample 876-5; src: tumour' ],
				      ['GSM2534','Bladder sample 956-2; src: tumour' ],
				      ['GSM2535','Bladder sample 967-3; src: tumour' ],
				      ['GSM2537','Bladder sample 989-1; src: tumour' ],
				      ]);

    if ($test_data) {
	is(scalar @{$data_table->{data}}, 7130);

	# try some random-ish data values:
	is($data_table->{data}->[1]->[0], 'A28102_at');
	is($data_table->{data}->[3]->[1], 'IFI44L');
	is($data_table->{data}->[53]->[6], '141.600');
	is($data_table->{data}->[25]->[12], '98.400');
	is($data_table->{data}->[543]->[7], '136.400');
	is($data_table->{data}->[27]->[7], '84.700');
	is($data_table->{data}->[85]->[18], '115.300');
	is($data_table->{data}->[252]->[11], '61.700');
	is($data_table->{data}->[853]->[15], '434.800');
	is($data_table->{data}->[96]->[25], '24.900');
	is($data_table->{data}->[34]->[24], '2535.500');
	is($data_table->{data}->[78]->[5], '47.500');
	is($data_table->{data}->[4]->[13], '78.900');
    } else {
	my $table=$data_table->{data};
	is_deeply($table, [], "got empty table");
    }

       
    my $header_descs=[map {$_->[1]} @{$data_table->{header}}];
    is_deeply($header_descs, [
'Platform reference identifier',
'identifier',
'Bladder sample 880-1; src: tumour',
'Bladder sample 625-1; src: tumour',
'Bladder sample 812-1; src: tumour',
'Bladder sample 847-1; src: tumour',
'Bladder sample 919-1; src: tumour',
'Bladder sample 1134-1; src: tumour',
'Bladder sample 1065-1; src: tumour',
'Bladder sample 1269-1; src: tumour',
'Bladder sample 1083-2; src: tumour',
'Bladder sample 1238-1; src: tumour',
'Bladder sample 1257-1; src: tumour',
'Bladder sample 1117-1; src: tumour',
'Bladder sample 1133-1; src: tumour',
'Bladder sample 1044-1; src: tumour',
'Bladder sample 1078-1; src: tumour',
'Bladder sample 1178-1; src: tumour',
'Bladder sample 875-1; src: tumour',
'Bladder sample 1068-1; src: tumour',
'Bladder sample 1164-1; src: tumour',
'Bladder sample 1032-1; src: tumour',
'Bladder sample 709_1; src: tumour',
'Bladder sample 928_1; src: tumour',
'Bladder sample 930_1; src: tumour',
'Bladder sample 934-1; src: tumour',
'Bladder sample 937-1; src: tumour',
'Bladder sample 968_1; src: tumour',
'Bladder sample 1062-2; src: tumour',
'Bladder sample 1070-1; src: tumour',
'Bladder sample 112-10; src: tumour',
'Bladder sample 1166-1; src: tumour',
'Bladder sample 1264-1; src: tumour',
'Bladder sample 1330-1; src: tumour',
'Bladder sample 320-7; src: tumour',
'Bladder sample 669-7; src: tumour',
'Bladder sample 716-2; src: tumour',
'Bladder sample 747-7; src: tumour',
'Bladder sample 876-5; src: tumour',
'Bladder sample 956-2; src: tumour',
'Bladder sample 967-3; src: tumour',
'Bladder sample 989-1; src: tumour',
			      ]);


    $record=shift @$records;
    isa_ok($record, 'subset');
    is($record->{dataset_id}, 'GDS183');
    is($record->{description}, 'tumor stage T1');
    is($record->{sample_id}, 'GSM2528,GSM2519,GSM2524,GSM2525,GSM2529,GSM2539,GSM2540,GSM2541,GSM2542,GSM2543,GSM2544');
    is($record->{type}, 'disease state');

    $record=shift @$records;
    isa_ok($record, 'subset');
    is($record->{dataset_id}, 'GDS183');
    is($record->{description}, 'tumor stage T2+');
    is($record->{sample_id}, 'GSM2505,GSM2510,GSM2512,GSM2506,GSM2509,GSM2515,GSM2526,GSM2538,GSM2513');
    is($record->{type}, 'disease state');

    $record=shift @$records;
    isa_ok($record, 'subset');
    is($record->{dataset_id}, 'GDS183');
    is($record->{description}, 'tumor stage Ta');
    is($record->{sample_id}, 'GSM2521,GSM2530,GSM2531,GSM2532,GSM2533,GSM2536,GSM2507,GSM2508,GSM2511,GSM2514,GSM2516,GSM2517,GSM2518,GSM2520,GSM2522,GSM2523,GSM2527,GSM2534,GSM2535,GSM2537');
    is($record->{type}, 'disease state');

    $record=shift @$records;
    isa_ok($record, 'subset');
    is($record->{dataset_id}, 'GDS183');
    is($record->{description}, 'grade 2');
    is($record->{sample_id}, 'GSM2521,GSM2530,GSM2531,GSM2532,GSM2533,GSM2536');
    is($record->{type}, 'tissue');

    $record=shift @$records;
    isa_ok($record, 'subset');
    is($record->{dataset_id}, 'GDS183');
    is($record->{description}, 'grade 3');
    is($record->{sample_id}, 'GSM2528,GSM2519,GSM2524,GSM2525,GSM2529,GSM2539,GSM2540,GSM2541,GSM2542,GSM2543,GSM2544,GSM2510,GSM2512,GSM2506,GSM2509,GSM2515,GSM2526,GSM2538,GSM2507,GSM2508,GSM2511,GSM2514,GSM2516,GSM2517,GSM2518,GSM2520,GSM2522,GSM2523,GSM2527,GSM2534,GSM2535,GSM2537');
    is($record->{type}, 'tissue');

    $record=shift @$records;
    isa_ok($record, 'subset');
    is($record->{dataset_id}, 'GDS183');
    is($record->{description}, 'grade 4');
    is($record->{sample_id}, 'GSM2513');
    is($record->{type}, 'tissue');

    $record=shift @$records;
    isa_ok($record, 'subset');
    is($record->{dataset_id}, 'GDS183');
    is($record->{description}, 'grade unknown');
    is($record->{sample_id}, 'GSM2505');
    is($record->{type}, 'tissue');

    wantarray? @r2:\@r2;
}


main(@ARGV);

