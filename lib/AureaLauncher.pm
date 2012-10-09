package AureaLauncher;
use Carp;
use Data::Dumper;
use namespace::autoclean;

use Moose;

has 'pheno1' => (is=>'ro', isa=>'Str', required=>1);
has 'pheno1_samples' => (is=>'ro', isa=>'ArrayRef[Str]', default=>sub{[]}); # change to 'ArrayRef[Sample'?
has 'pheno2' => (is=>'ro', isa=>'Str', required=>1);
has 'pheno2_samples' => (is=>'ro', isa=>'ArrayRef[Str]', default=>sub{[]});
has 'classifier' => (is=>'ro', isa=>'Str', required=>1); # change to object?
has 'start_ts' => (is=>'rw', isa=>'DateTime');
has 'stop_ts' => (is=>'rw', isa=>'DateTime');
has 'results' => (is=>'rw', isa=>'ClassifierResults');

has 'python_exe' => (is=>'ro', default=>'/usr/bin/python');
has 'aurea_exe' => (is=>'ro', default=>'/home/ISB/vcassen/l/AUREA/scripts/testScripts/aurea.py');
has 'valid_classifiers' => (is=>'ro', default=>sub {[qw(tsp tsn mc_dicac)]});
has 'aurea_config' => (is=>'ro', default=>'/home/ISB/vcassen/l/AUREA/scripts/testScripts/config.xml');

sub duration {}			# how long did aurea take
sub store {}			# store results
sub as_str {}			
sub add_sample {
    my ($self, $pheno, $sample)=@_;
}

# compute the classifer results by calling aurea.py (or equivalent)
# returns ClassiferResults object (I guess)
sub launch {
    my ($self)=@_;
    # create_csv_files()
    my $pheno1_csv=$self->create_csv($self->pheno1);
    my $pheno2_csv=$self->create_csv($self->pheno2);

    # call aurea, capture output
    my @cmd;
    push @cmd, $self->aurea_exe;
    push @cmd '-a', $pheno1_csv;
    push @cmd '-b', $pheno2_csv;
    push @cmd, '-l', $self->classifer;
    push @cmd, '-c', $self->config;
    warn "cmd is ", join(' ', @cmd);
    my $pid=fork;
    if (! defined $pid) {	# error
	die $!;
    } elsif ($pid==0) {		# child
	exec @cmd or die $!;
    } 

    # so, yeah, are we gonna wait around for this to finish or what?
    
    
    # store output to self
    # persist self
    # return results
}

__PACKAGE__->meta->make_immutable;

1;
