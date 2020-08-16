package App::Fenix::Controller;

# ABSTRACT: The Controller

use 5.010;
use utf8;
use Moo;
use Try::Tiny;
use Path::Tiny;
use File::Basename;
use IPC::System::Simple 1.17 qw(run);
use App::Fenix::Types qw(
    Maybe
    FenixOptions
    FenixConfig
    FenixModel
    FenixState
    FenixView
    TkFrame
);

use App::Fenix::X qw(hurl);
use App::Fenix::Options;
use App::Fenix::Config;
use App::Fenix::Model;
use App::Fenix::State;
use App::Fenix::Refresh;
use App::Fenix::View;

has options => (
    is      => 'ro',
    isa     => FenixOptions,
    lazy    => 1,
    default => sub {
        return App::Fenix::Options->new_with_options;
    },
    handles => [qw(
        verbose
        debug
    )],
);

has config => (
    is      => 'ro',
    isa     => FenixConfig,
    lazy    => 1,
    builder => '_build_config',
);

sub _build_config {
    my $self   = shift;
    my $mnemonic = $self->options->mnemonic || 'test-tk';
    my $config = try {
        App::Fenix::Config->new( mnemonic => $mnemonic );
    }
    catch {
        hurl controller => 'EE Configuration error: "{error}"',
            error => $_;
    };
    $config->debug( $self->options->debug );
    $config->verbose( $self->options->verbose );
    return $config;
}

has 'model' => (
    is      => 'ro',
    isa     => FenixModel,
    lazy    => 1,
    builder => '_build_model',
    handles => [qw(
        get_dir_for
        get_file_for
        get_path_for
    )],
);

sub _build_model {
    my $self  = shift;
    my $model = try {
        App::Fenix::Model->new(
            config => $self->config,
        );
    }
    catch {
        hurl model => 'EE Model error: "{error}"', error => $_;
    };
    return $model;
}

has 'view' => (
    is       => 'ro',
    # isa      => FenixView,
    lazy     => 1,
    required => 1,
    builder  => '_build_view',
);

sub _build_view {
    my $self = shift;
    return App::Fenix::View->new(
        config => $self->config,
        model  => $self->model,
    );
}

has 'frame' => (
    is      => 'ro',
    isa     => TkFrame,
    default => sub {
        my $self = shift;
        return $self->view->frame;
    },
);

has 'state' => (
    is      => 'rw',
    isa     => FenixState,
    lazy    => 1,
    default => sub {
        return App::Fenix::State->new;
    }
);

sub log_message {
    my ($self, $msg) = @_;
    my $newline = ( $msg =~ /\.\./msg ) ? 0 : 1;
    $self->view->log_message($msg, $newline);
    return;
}

sub _init {
    my $self = shift;
    return;
}

sub _setup_events {
    my $self = shift;

    #-  Menu Bar

    #-- Exit
    $self->view->event_handler_for_menu(
        'mn_qt',
        sub { $self->on_quit }
    );

    #-  Notebook

    $self->view->event_handler_for_notebook(
        'rec',
        sub { say "on_page_rec_activate" }
    );
    $self->view->event_handler_for_notebook(
        'lst',
        sub { say "on_page_lst_activate" }
    );
    $self->view->event_handler_for_notebook(
        'det',
        sub { say "on_page_det_activate" }
    );

    #-  Tool Bar

    #-- Save
    $self->view->event_handler_for_tb_button(
        'tb_sv',
        sub { $self->on_save }
    );

    #-- Reload
    $self->view->event_handler_for_tb_button(
        'tb_rr',
        sub { $self->on_reload }
    );

    #-- Quit
    $self->view->event_handler_for_tb_button(
        'tb_qt',
        sub { $self->on_quit }
    );

    #-  Keys

    #-- Quit Ctrl-q
    $self->view->event_handler_for_key('<Control-q>', 'on_close_window');

    return;
}

sub on_quit {
    my $self = shift;
    print "Shutting down...\n";
    $self->view->on_close_window(@_);
}

sub BUILD {
    my ( $self, $args ) = @_;
    $self->_setup_events;
    $self->state->add_observer(
        App::Fenix::Refresh->new( view => $self->view ) );
    $self->log_message('[II] Welcome to Fenix (GUI)!');
    $self->state->set_state('idle');
    $self->_init;
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 ATTRIBUTES

=head1 METHODS

=head3 BUILD

=cut
