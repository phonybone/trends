package GEO::Soft;
use strict;
use warnings;
use Carp;
use Data::Dumper;

# Mixin class to parse GEO Soft formatted records
# SOFT format:
# lines starting with:
# ^: new (sub)object
# !: attribute
# #: data table header
# none of above: data table row

# return a hash[ref] of a parse document
# throws exceptions on formatting errors, etc
sub parse {
    my ($self, $txt_rec)=@_;

    my $record={data=>[], data_header=>[]};
    my $sub_r;
    my $sub_r_name;

    my @lines=split(/\n/, $txt_rec);
    foreach (@lines) {
	chomp;
	my $first=substr($_,0,1);
	if ($first eq '^') {
	    my ($k,$v)=split(/\s*=\s*/);
	    $sub_r_name=lc $k;
	    $sub_r={$sub_r_name=>$v};
	    push @{$record->{$sub_r_name}}, $sub_r; # jezuz
	} elsif ($first eq '!') {
	    next if /^.dataset_table[begin|end]/;
	    my ($k,$v)=split(/\s*=\s*/); # $v may be undef
	    $k=lc $k;
	    $k=~s/${sub_r_name}_//; # '\' to make emacs indenting happy
	    $sub_r->{$k}=$v;
	} elsif ($first eq '#') {	# likewise
	    next if /^.ID_REF/ || /^.IDENTIFIER/; # using '.' instead of '#' in regex due to indenting
	    my $header=[split(/\s+/)];
	    $record->{data_header}=$header;
	} else {
	    my $row=[split(/\s+/)];
	    push @{$record->{data}}, $row;
	}
    }
    
}


1;
