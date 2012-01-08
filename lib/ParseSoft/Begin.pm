package ParseSoft::Begin;
use base qw(Workflow::Action);
use Workflow::Exception qw(workflow_error);

sub execute {
    my ($self, $wf)=@_;
    my $context=$wf->context;

}
