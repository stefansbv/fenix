package App::Fenix::Refresh;

# ABSTRACT: An Observer for the GUI

use feature 'say';
use Moo;
use App::Fenix::Types qw(
    FenixRules
    FenixView
);
use App::Fenix::Rules;
use namespace::autoclean;

with 'App::Fenix::Role::Observer';

has 'view' => (
    is   => 'ro',
    isa  => FenixView,
);

has 'rules' => (
    is      => 'ro',
    isa     => FenixRules,
    lazy    => 1,
    builder => '_build_rules',
    handles => [ 'get_rules' ],
);

sub _build_rules {
    return App::Fenix::Rules->new;
}

sub update {
    my ( $self, $subject ) = @_;
    say "refresh: update event";
    my $state = $subject->get_state;
    $self->view->set_control_state( $state, $self->get_rules($state) );
    return;
}

1;
