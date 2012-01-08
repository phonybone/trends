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

    my $soft_file=File::Spec->catfile($trends_dir, qw(data GEO series GSE1832 GSE1832_family.soft));
    ok(-r $soft_file, "got test file");

    my $parser=$class->new($soft_file);
    isa_ok($parser, $class, "got $class");

    my $soft_records=$parser->parse;
    my $n_expected_records=18;
    is (scalar @$soft_records, $n_expected_records, "got $n_expected_records records");

    test_GSE1832($soft_records);
}

sub test_GSE1832 {
    my ($records)=@_;
#    my @r2=@$records;		# save a copy for later; this routine chews @$records

    my $record=shift @$records;
    isa_ok($record, 'database');
    is ($record->{geo_id}, "GeoMiame");
    is($record->{name}, 'Gene Expression Omnibus (GEO)');
    is($record->{institute}, 'NCBI NLM NIH');
    is($record->{web_link}, 'http://www.ncbi.nlm.nih.gov/geo');
    is($record->{email}, 'geo@ncbi.nlm.nih.gov');
    is_deeply ($record->{__table}, {header=>[], data=>[]}, "no database_table");

    $record=shift @$records;
    isa_ok($record, 'series');
    is ($record->{geo_id}, "GSE1832");
    is ($record->{title}, 'Time and Exercise effects on Human Skeletal Muscle');
    is ($record->{geo_accession}, "GSE1832");
    is ($record->{status}, "Public on Oct 14 2004");
    is ($record->{submission_date}, "Oct 11 2004");
    is ($record->{last_update_date}, "Aug 05 2011");
    is ($record->{pubmed_id}, "14519196");
    is ($record->{web_link}, "http://www.pubmedcentral.nih.gov/articlerender.fcgi?tool=pubmed&pubmedid=14519196");
    is_deeply ($record->{summary}, ["Four healthy human volunteers underwent an acute bout of resistance exercise with the right leg at 2 pm. Biopsies were removed from the Vastus Lateralis muscle 6 h (8 pm) and 18 h (8 am) after exericise",
				    "Keywords = Human skeletal muscle",
				    "Keywords = resistance exerise",
				    "Keywords = diurnal",
				    "Keywords = circadian",
				    "Keywords: time-course"]);
    is ($record->{type}, "Expression profiling by array");
    is_deeply ($record->{contributor}, ["Alexander,C,Zambon",
					"Erin,L,McDearmon",
					"Nathan,,Salomonis",
					"Karen,M,Vranizan",
					"Kirsten,L,Johansen",
					"Deborah,,Adey",
					"Joseph,S,Takahashi",
					"Morris,,Schambelan",
					"Bruce,R,Conklin"]);
    is_deeply ($record->{sample_id}, ["GSM32066",
				      "GSM32097",
				      "GSM32098",
				      "GSM32099",
				      "GSM32100",
				      "GSM32101",
				      "GSM32102",
				      "GSM32103",
				      "GSM32104",
				      "GSM32105",
				      "GSM32106",
				      "GSM32107",
				      "GSM32108",
				      "GSM32109",
				      "GSM32110"]);
    is ($record->{contact_name}, "Alexander,C,Zambon");
    is ($record->{contact_laboratory}, "Paul Insel Lab");
    is ($record->{contact_department}, "Pharmacology");
    is ($record->{contact_institute}, "University of Clalifornia, San Diego");
    is ($record->{contact_address}, "9500 Gilman Dr.");
    is ($record->{contact_city}, "La Jolla");
    is ($record->{contact_state}, "CA");
    is ($record->{'contact_zip/postal_code'}, "92093-0636");
    is ($record->{contact_country}, "USA");
    is ($record->{supplementary_file}, "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/supplementary/series/GSE1832/GSE1832_RAW.tar");
    is ($record->{platform_id}, "GPL8300");
    is ($record->{platform_taxid}, "9606");
    is ($record->{sample_taxid}, "9606");
    is_deeply ($record->{__table}, {header=>[], data=>[]}, "no series_table");

    $record=shift @$records;
    isa_ok($record, 'platform');
    is ($record->{geo_id}, "GPL8300");
    is ($record->{title}, "[HG_U95Av2] Affymetrix Human Genome U95 Version 2 Array");
    is ($record->{geo_accession}, "GPL8300");
    is ($record->{status}, "Public on Mar 16 2009");
    is ($record->{submission_date}, "Mar 13 2009");
    is ($record->{last_update_date}, "Aug 05 2011");
    is ($record->{technology}, "in situ oligonucleotide");
    is ($record->{distribution}, "commercial");
    is ($record->{organism}, "Homo sapiens");
    is ($record->{taxid}, "9606");
    is ($record->{manufacturer}, "Affymetrix");
    is ($record->{manufacture_protocol}, "see manufacturer's web site");
    is_deeply ($record->{description}, ["Affymetrix submissions are typically submitted to GEO using the GEOarchive method described at http://www.ncbi.nlm.nih.gov/projects/geo/info/geo_affy.html",
					"",
					"Based on this UniGene build and associated annotations, the HG-U95Av2 array represents approximately 10,000 full-length genes.",
					""]);
    is_deeply ($record->{web_link}, ["http://www.affymetrix.com/support/technical/byproduct.affx?product=hgu95",
				     "http://www.affymetrix.com/analysis/index.affx"]);
    is ($record->{contact_name}, ",,Affymetrix, Inc.");
    is ($record->{contact_email}, "geo\@ncbi.nlm.nih.gov, support\@affymetrix.com");
    is ($record->{contact_phone}, "888-362-2447");
    is ($record->{contact_institute}, "Affymetrix, Inc.");
    is ($record->{contact_address}, "");
    is ($record->{contact_city}, "Santa Clara");
    is ($record->{contact_state}, "CA");
    is ($record->{'contact_zip/postal_code'}, "95051");
    is ($record->{contact_country}, "USA");
    is ($record->{contact_web_link}, "http://www.affymetrix.com/index.affx");
    is ($record->{data_row_count}, "12625");
    isa_ok($record->{__table}, 'HASH', "got database_table");

    ########################################################################

    my $data_table=$record->{__table};
    is(ref $data_table, 'HASH');
    is(ref $data_table->{data}, 'ARRAY');
    is(ref $data_table->{header}, 'ARRAY');

    is_deeply($data_table->{header}, [
				      ['ID', 'Affymetrix Probe Set ID LINK_PRE:"https://www.affymetrix.com/LinkServlet?array=U95&probeset="'],
				      ['GB_ACC', 'GenBank Accession Number LINK_PRE:"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Search&db=Nucleotide&term="'],
				      ['SPOT_ID', 'identifies controls and TIGR accessions'],
				      ['Species Scientific Name', 'The genus and species of the organism represented by the probe set.'],
				      ['Annotation Date', 'The date that the annotations for this probe array were last updated. It will generally be earlier than the date when the annotations were posted on the Affymetrix web site.'],
				      ['Sequence Type', ''],
				      ['Sequence Source', 'The database from which the sequence used to design this probe set was taken.'],
				      ['Target Description', ''],
				      ['Representative Public ID', 'The accession number of a representative sequence. Note that for consensus-based probe sets, the representative sequence is only one of several sequences (sequence sub-clusters) used to build the consensus sequence and it is not directly used to derive the probe sequences. The representative sequence is chosen during array design as a sequence that is best associated with the transcribed region being interrogated by the probe set. Refer to the "Sequence Source" field to determine the database used.'],
				      ['Gene Title', 'Title of Gene represented by the probe set.'],
				      ['Gene Symbol', 'A gene symbol, when one is available (from UniGene).'],
				      ['ENTREZ_GENE_ID', 'Entrez Gene Database UID LINK_PRE:"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=gene&cmd=Retrieve&dopt=Graphics&list_uids=" DELIMIT:" /// "'],
				      ['RefSeq Transcript ID', 'References to multiple sequences in RefSeq. The field contains the ID and Description for each entry, and there can be multiple entries per ProbeSet.'],
				      ['Gene Ontology Biological Process', 'Gene Ontology Consortium Biological Process derived from LocusLink.  Each annotation consists of three parts: "Accession Number // Description // Evidence". The description corresponds directly to the GO ID. The evidence can be "direct", or "extended".'],
				      ['Gene Ontology Cellular Component', 'Gene Ontology Consortium Cellular Component derived from LocusLink.  Each annotation consists of three parts: "Accession Number // Description // Evidence". The description corresponds directly to the GO ID. The evidence can be "direct", or "extended".'],
				      ['Gene Ontology Molecular Function', 'Gene Ontology Consortium Molecular Function derived from LocusLink.  Each annotation consists of three parts: "Accession Number // Description // Evidence". The description corresponds directly to the GO ID. The evidence can be "direct", or "extended".'],
				      ]);
    is(scalar @{$data_table->{data}}, 12626);

    # try some random-ish data values:
    is($data_table->{data}->[1]->[0],    '1000_at');
    is($data_table->{data}->[3]->[1],    'X65962');
    is($data_table->{data}->[53]->[6],   '2009');
    is($data_table->{data}->[25]->[12],  '/DEFINITION=HSIFR14');
    is($data_table->{data}->[543]->[7],  'Exemplar');
    is($data_table->{data}->[27]->[7],   'Exemplar');
    is($data_table->{data}->[85]->[18],  'gene,');
    is($data_table->{data}->[252]->[11], '/FEATURE=');
    is($data_table->{data}->[853]->[15], 'mRNA');
    is($data_table->{data}->[96]->[25],  '0007165');
    is($data_table->{data}->[34]->[24],  'U07806');
    is($data_table->{data}->[78]->[5],   '11,');
    is($data_table->{data}->[4]->[13],   'Homo');

       
    $record=shift @$records;
    isa_ok($record, 'sample');
    is($record->{title}, "Patient 1 Nonexercise 8 pm");
    is($record->{geo_accession}, "GSM32066");
    is($record->{status}, "Public on Oct 14 2004");
    is($record->{submission_date}, "Oct 11 2004");
    is($record->{last_update_date}, "Mar 16 2009");
    is($record->{type}, "RNA");
    is($record->{channel_count}, "1");
    is($record->{source_name_ch1}, "vastus lateralis muscle");
    is($record->{organism_ch1}, "Homo sapiens");
    is($record->{taxid_ch1}, "9606");
    is($record->{molecule_ch1}, "total RNA");
    is_deeply($record->{description}, ["5 healthy male volunteers exercised with the right leg at 2 pm. Biopsies were removed from the exercised and nonexercised leg 6h and 18h later",
				       "Keywords = Human",
				       "Keywords = resistance exercise",
				       "Keywords = muscle",
				       "Keywords = circadian"]);
    is($record->{platform_id}, "GPL8300");
    is($record->{contact_name}, "Alexander,C,Zambon");
    is($record->{contact_laboratory}, "Paul Insel Lab");
    is($record->{contact_department}, "Pharmacology");
    is($record->{contact_institute}, "University of Clalifornia, San Diego");
    is($record->{contact_address}, "9500 Gilman Dr.");
    is($record->{contact_city}, "La Jolla");
    is($record->{contact_state}, "CA");
    is($record->{'contact_zip/postal_code'}, "92093-0636");
    is($record->{contact_country}, "USA");
    is($record->{supplementary_file}, "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/supplementary/samples/GSM32nnn/GSM32066/GSM32066.CEL.gz");
    is($record->{series_id}, "GSE1832");
    is($record->{data_row_count}, "12625");
    is_deeply($record->{__table}->{header}, [['ID_REF', ' '], ['VALUE', 'RMA signal value']]);
    is_deeply($record->{__table}->{data}->[0]->[0], "ID_REF");
    is_deeply($record->{__table}->{data}->[0]->[1], "VALUE");
    is_deeply($record->{__table}->{data}->[1]->[0], "100_g_at");
    is_deeply($record->{__table}->{data}->[1]->[1], "1216.364515");
    is_deeply($record->{__table}->{data}->[23]->[1], "103.0604712");
    is_deeply($record->{__table}->{data}->[42]->[1], "109.2860178");
    is_deeply($record->{__table}->{data}->[8]->[1], "92.43715528");
    is_deeply($record->{__table}->{data}->[473]->[1], "539.8629418");
    is_deeply($record->{__table}->{data}->[98]->[1], "80.61798108");
    is_deeply($record->{__table}->{data}->[185]->[1], "1133.023082");
    is_deeply($record->{__table}->{data}->[427]->[0], "1395_at");
    is_deeply($record->{__table}->{data}->[111]->[0], "110_at");
    is_deeply($record->{__table}->{data}->[854]->[0], "1762_at");
    is_deeply($record->{__table}->{data}->[7543]->[0], "37471_at");
    is_deeply($record->{__table}->{data}->[236]->[0], "1214_s_at");
    is_deeply($record->{__table}->{data}->[255]->[0], "1233_s_at");
    is_deeply($record->{__table}->{data}->[742]->[0], "1660_at");
    is_deeply($record->{__table}->{data}->[947]->[0], "1849_s_at");
    is_deeply($record->{__table}->{data}->[7343]->[0], "37273_at");
    

    $record=shift @$records;
    isa_ok($record, 'sample');
    is($record->{title}, 'Patient 2 Nonexericse 8 pm');
    is($record->{geo_accession}, 'GSM32097');
    is ($record->{status}, "Public on Oct 14 2004");
    is ($record->{submission_date}, "Oct 11 2004");
    is ($record->{last_update_date}, "Mar 16 2009");
    is ($record->{type}, "RNA");
    is ($record->{channel_count}, "1");
    is ($record->{source_name_ch1}, "Vastus Lateralis Muscle");
    is ($record->{organism_ch1}, "Homo sapiens");
    is ($record->{taxid_ch1}, "9606");
    is ($record->{molecule_ch1}, "total RNA");
    is_deeply ($record->{description}, ["5 healthy male volunteers exercised with the right leg at 2 pm. Biopsies were removed from the exercised and nonexercised leg 6h and 18h later",
					"Keywords = Human",
					"Keywords = resistance exercise",
					"Keywords = muscle",
					"Keywords = circadian"]);
    is ($record->{platform_id}, "GPL8300");
    is ($record->{contact_name}, "Alexander,C,Zambon");
    is ($record->{contact_laboratory}, "Paul Insel Lab");
    is ($record->{contact_department}, "Pharmacology");
    is ($record->{contact_institute}, "University of Clalifornia, San Diego");
    is ($record->{contact_address}, "9500 Gilman Dr.");
    is ($record->{contact_city}, "La Jolla");
    is ($record->{contact_state}, "CA");
    is ($record->{'contact_zip/postal_code'}, "92093-0636");
    is ($record->{contact_country}, "USA");
    is ($record->{supplementary_file}, "ftp://ftp.ncbi.nih.gov/pub/geo/DATA/supplementary/samples/GSM32nnn/GSM32097/GSM32097.CEL.gz");
    is ($record->{series_id}, "GSE1832");
    is ($record->{data_row_count}, "12625");




    # we could continue testing in this vein, but we won't.
}


main(@ARGV);

