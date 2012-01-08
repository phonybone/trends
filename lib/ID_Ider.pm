package ID_Ider;
use Moose;

#
# This package attempts to identify where a particular biological id originates.
# It does this by comparing each candidate id against a group of regular expressions,
# and reports on all the regex's that recognize the candidate id.
#

our %id_types=(
	       pathway_nature_name => 'NCI Nature Pathway Interaction Database Name',
	       protein_uniprot_symbol => 'UniProt Protein Symbol',
	       protein_refseq => 'RefSeq protein id',
	       probe_nu => 'nucleotide universal id',
	       pathway_reactome_title => 'Reactome Title',
	       pathway_reactome_id => 'Reactome Pathway id',
	       probe_lumi => 'Illumina probe id',
	       protein_ncbi_genbank => 'NCBI Genbank protein id',
	       chip_agilent_title => 'Agilent array title',
	       function_go_description => 'GO description',
	       function_omim => 'OMIM number',
	       pathway_nature_title => 'NCI Nature Pathway Interaction Database Title',
	       chip_affy_gpl => 'Affymetrix array GPL id',
	       pathway_kegg_id => 'KEGG Pathway id',
	       sequence_agilent => 'Agilent probeset sequence',
	       chip_lumi_title => 'Illumina array title',
	       organism_name_common => 'organism',
	       probe_affy => 'Affymetrix probeset id',
	       protein_uniprot => 'UniProt id',
	       gene_rgd => 'Rat Genome Database (RGD) id',
	       gene_description => 'gene description',
	       gene_entrez => 'Entrez gene id',
	       function_omim_description => 'OMIM description',
	       protein_ensembl => 'Ensembl protein id',
	       chip_agilent_id => 'Agilent array id',
	       protein_ipi_description => 'IPI protein description',
	       transcript_ncbi_genbank => 'GenBank Nucleotide Accession Number',
	       probe_agilent => 'Agilent probeset id',
	       sequence_nu => 'nucleotide universal id sequence',
	       peptide_pepatlas => 'Peptide Atlas id',
	       protein_ipi => 'IPI id',
	       transcript_ncbi_genbank_gi => 'NCBI Genbank Transcript GI',
	       gene_ensembl => 'Ensembl gene id',
	       transcript_ensembl => 'Ensembl transcript id',
	       gene_mgi => 'Mouse Genome Informatics (MGI) id',
	       chip_affy_title => 'Affymetrix array title',
	       gene_unigene => 'UniGene id',
	       protein_ncbi_genbank_gi => 'NCBI Genbank protein GI ID',
	       gene_symbol => 'gene symbol',
	       pathway_kegg_title => 'KEGG Pathway Title',
	       gene_known => 'UCSC known gene id',
	       protein_uniprot_description => 'UniProt Protein Description',
	       chip_agilent_gpl => 'Agilent array GPL id',
	       publication_pubmed => 'Pubmed ID',
	       pathway_biocarta_title => 'BioCarta Pathway Title',
	       transcript_refseq => 'RefSeq transcript id',
	       mutation_cosmic_mutated => 'Gene Mutated in Catalogue of Somatic Mutations in Cancer (COSMIC)?',
	       sequence_affy => 'Affymetrix probeset sequence',
	       chip_lumi_id => 'Illumina array id',
	       chip_lumi_gpl => 'Illumina array GPL id',
	       transcript_epcondb => 'EpconDB transcript id',
	       chip_affy_id => 'Affymetrix array id',
	       reaction_ec => 'EC number',
	       function_go => 'GO id',
	       gene_symbol_synonym => 'gene synonym',
	       );

my %regexs=(
	    gene_entrez => [ qr/^\d+$/ ],
	    gene_mgi => [ qr/^MGI_\d+$/ ],
	    probe_affy => [ qr/^\d+_at$/, qr/^\d+_[afgirsx]_at$/, qr/^AFFX.*-[\dM]_at$/ ],
	    );

sub id_id {
    my ($self, $id)=@_;

    my @id_types=();
    while (my ($id_type, $re_list)=each %regexs) {
	foreach my $re (@$re_list) {
	    if ($id=~/$re/) {
		push @id_types, $id_type;
		last;		# this list
	    }
	}
    }
    wantarray? @id_types:\@id_types;
}




1;
