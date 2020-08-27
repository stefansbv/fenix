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

    # GUI
    my $gui_state = $subject->get_state('gui_state');
    $self->view->set_control_state( $gui_state, $self->get_rules($gui_state) );

    # Connection
    my $con_state = $subject->get_state('conn_state');
    my $dbname    = $subject->get_state('db_name');
    if ( $con_state eq 'connected' ) {
        $self->view->set_status( 'connectyes16', 'cn' );
        $self->view->set_status( $dbname, 'db', 'darkgreen' );
    }
    else {
        $self->view->set_status( 'connectno16', 'cn' );
        $self->view->set_status( $dbname, 'db', 'darkred' );
    }
    return;
}

1;
