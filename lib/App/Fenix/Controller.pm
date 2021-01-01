package App::Fenix::Controller;

# ABSTRACT: The Controller

use 5.010;
use utf8;
use Moo;
use Try::Tiny;
use Path::Tiny;
use File::Basename;
use IPC::System::Simple 1.17 qw(run);
use English;                                 # for $PERL_VERSION
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
use App::Fenix::Exceptions;
use App::Fenix::Tk::Dialog::Message;
use App::Fenix::Tk::Dialog::Login;

with 'MooX::Log::Any';

has options => (
    is      => 'ro',
    isa     => FenixOptions,
    lazy    => 1,
    default => sub {
        return App::Fenix::Options->new_with_options;
    },
    handles => [
        qw(
            mnemonic
            verbose
            debug
            list
            )
    ],
);

has 'config' => (
    is      => 'ro',
    isa     => FenixConfig,
    lazy    => 1,
    builder => '_build_config',
);

sub _build_config {
    my $self   = shift;
    $self->mnemonic('test-tk') if !$self->mnemonic; # default mnemonic
    my $config = try {
        App::Fenix::Config->new( mnemonic => $self->mnemonic );
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
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->view->frame;
    },
);

has '_state' => (
    is      => 'rw',
    isa     => FenixState,
    lazy    => 1,
    default => sub {
        return App::Fenix::State->new;
    },
    handles => [qw(
        add_observer
        conn_state
        db_name
        set_state
        get_state
        is_state
    )],
);

sub log_message {
    my ($self, $msg) = @_;
    my $newline = ( $msg =~ /\.\./msg ) ? 0 : 1;
    $self->view->log_message($msg, $newline);
    return;
}

sub _init {
    my $self = shift;
    my $error = '';
    $self->delay_start(
        sub {
            say 'connecting...';
            try {
                $self->model->db->dbh;
            }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    if ( $e->isa('Exception::Db::Connect') ) {
                        $error = $e->usermsg;
                        say "[EE] '$error'" if $self->debug;
                        $error = $self->connect_dialog($error);
                    }
                    else {
                        die "[EE] '$_'";
                    }
                }
            }
            finally {
                my $state = $error ? 'not_connected' : 'connected';
                $self->log_message("# connection status = $state");
                $self->set_state( 'conn_state', $state );
                if ($error) {
                    $self->on_quit;
                }
            };
        }
    );
    return;
}

sub is_connected {
    my $self = shift;
    return $self->get_state('conn_state') eq 'connected';
}

sub connect_dialog {
    my ( $self, $error ) = @_;
  TRY:
    while ( not $self->is_connected ) {

        # Show login dialog if still not connected
        my $return_string = $self->login_dialog($error);
        if ( $return_string eq 'cancel' ) {
            $self->view->set_status( 'Login cancelled', 'ms' );
            last TRY;
        }

        # Try to connect only if user and pass are provided
        if ( $self->config->user and $self->config->password ) {
            $error = '';
            # say "try again...";
            # say 'with:';
            # say " user: ", $self->config->user;
            # say " pass: ", $self->config->password;
            $self->model->db->target->username( $self->config->user );
            $self->model->db->target->password( $self->config->password );
            # say 'target:';
            # say " user: ", $self->model->db->target->username;
            # say " pass: ", $self->model->db->target->password;
            $self->model->db->target->engine->reset_connector;
            try {
                $self->model->db->dbh;
            }
            catch {
                if ( my $e = Exception::Base->catch($_) ) {
                    if ( $e->isa('Exception::Db::Connect') ) {
                        $error = $e->usermsg;
                        say "[EE] '$error'" if $self->debug;
                    }
                }
                else {
                    die "[EE] '$_'";
                }
            }
            finally {
                my $state = $error ? 'not_connected' : 'connected';
                $self->set_state( 'conn_state', $state );
            };
        }
        else {
            $error = 'error#User and password are required';
        }
    }
    return $error;
}

sub message_dialog {
    my ( $self, $message, $details, $icon, $type, $geom ) = @_;
    my $dlg = App::Fenix::Tk::Dialog::Message->new( view => $self->view );
    $dlg->message( $message, $details, $icon, $type, $geom );
    return;
}

sub login_dialog {
    my ( $self, $error ) = @_;
    my $dlg = App::Fenix::Tk::Dialog::Login->new( view => $self->view );
    return $dlg->login($error);
}

sub _setup_events {
    my $self = shift;

    #-  Menu Bar

    #-- Exit
    $self->view->event_handler_for_menu(
        'mn_qt',
        sub { $self->on_quit }
    );

    #-- Help
    $self->view->event_handler_for_menu(
        'mn_gd',
        sub {
            $self->guide;
        }
    );

    #-- About
    $self->view->event_handler_for_menu(
        'mn_ab',
        sub {
            $self->about;
        }
    );

    #-- Preview RepMan report
    $self->view->event_handler_for_menu(
        'mn_pr',
        sub { $self->repman; }
    );

    #-- Generate PDF from TT model
    $self->view->event_handler_for_menu(
        'mn_tt',
        sub { $self->ttgen; }
    );

    #-- Edit RepMan report metadata
    $self->view->event_handler_for_menu(
        'mn_er',
        sub {
            $self->screen_module_load('Reports','tools');
        }
    );

    #-- Edit Templates metadata
    $self->view->event_handler_for_menu(
        'mn_et',
        sub {
            $self->screen_module_load('Templates','tools');
        }
    );

    #-- Admin - set default mnemonic
    $self->view->event_handler_for_menu(
        'mn_mn',
        sub {
            $self->set_mnemonic();
        }
    );

    #-- Admin - configure
    $self->view->event_handler_for_menu(
        'mn_cf',
        sub {
            $self->set_app_configs();
        }
    );

    $self->view->event_handler_for_menu(
        'mn_cfg',
        sub {
            $self->screen_module_load('Configs','tools');
        }
    );

    #- Custom application menu from menu.yml

    foreach my $item ( @{ $self->view->menu_bar->get_app_menu_popup_list } ) {
        $self->view->event_handler_for_menu(
            $item,
            sub {
                $self->screen_module_load($item);
            }
        );
    }

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
    $self->log->info("done.");
    $self->view->on_close_window(@_);
}

sub delay_start {
    my ($self, $code) = @_;
    $self->view->frame->after( 1500, $code );
    return;
}

sub BUILD {
    my ( $self, $args ) = @_;
    if ($self->list) {
        $self->show_mnemonics;
        exit;
    }
    $self->add_observer(
        App::Fenix::Refresh->new( view => $self->view ) );
    $self->log_message('[II] Welcome to Fenix!');
    my $cc = $self->config->connection;
    say "# mnemonic  = ", $self->mnemonic;
    say "# driver    = ", $cc->driver;
    say "# dbname    = ", $cc->dbname;
    $self->set_state('gui_state', 'idle');
    $self->set_state('db_name', $cc->dbname);
    $self->_setup_events;
    $self->_init;
    return;
}

sub show_mnemonics {
    my $self = shift;
    my $apps_path = path $self->config->sharedir, 'apps';
    my $iter = $apps_path->iterator;
    say "Mnemonics (configurations):";
    while ( my $path = $iter->() ) {
        my $name = $path->basename;
        my $v = ' '; # $self->validate_config($name) ? ' ' : '!';
        my $d = ' '; # $default eq $name             ? '*' : ' ';
        say " ${d}>${v}$name";
    }
    say " in $apps_path";
    say "";
    return;
}

sub application_class {
    my ( $self, $module ) = @_;
    $module //= $self->config->get_application('module');
    return qq{App::Fenix::Tk::App::${module}};
}

sub screen_module_load {
    my ( $self, $module, $from_tools ) = @_;
    print "Loading >$module<\n" if $self->verbose;
    my $rscrstr = lc $module;

    my ( $class, $module_file )
        = $self->screen_module_class( $module, $from_tools );
    eval { require $module_file };
    if ($@) {
        print "EE: Can't load '$module_file'\n";
        return;
    }

    unless ( $class->can('run_screen') ) {
        my $msg = "EE: Screen '$class' can not 'run_screen'";
        print "$msg\n";
        $self->_log->error($msg);
        return;
    }

    # New screen instance
    $self->{_rscrobj} = $class->new(
        {   scrcfg  => $rscrstr,
            toolscr => $from_tools
        },
    );
    $self->_log->trace("New screen instance: $module");
}

sub about {
    my $self = shift;

    my $gui = $self->view->frame;

    # Create a dialog.
    require Tk::DialogBox;
    my $dbox = $gui->DialogBox(
        -title   => 'Despre ... ',
        -buttons => ['Close'],
    );

    # Windows has the annoying habit of setting the background color
    # for the Text widget differently from the rest of the window.  So
    # get the dialog box background color for later use.
    my $bg = $dbox->cget('-background');

    # Insert a text widget to display the information.
    my $text = $dbox->add(
        'Text',
        -height     => 15,
        -width      => 35,
        -background => $bg
    );

    # Define some fonts.
    my $textfont = $text->cget('-font')->Clone( -family => 'Helvetica' );
    my $italicfont = $textfont->Clone( -slant => 'italic' );
    $text->tag(
        'configure', 'italic',
        -font    => $italicfont,
        -justify => 'center',
    );
    $text->tag(
        'configure', 'normal',
        -font    => $textfont,
        -justify => 'center',
    );

    # Framework version
    my $PROGRAM_NAME = '== Fenix ==';
    my $PROGRAM_VER  = $App::Bonus::VERSION || 'development';

    # Add the about text.
    $text->insert( 'end', "\n" );
    $text->insert( 'end', $PROGRAM_NAME . "\n", 'normal' );
    $text->insert( 'end', "Version: " . $PROGRAM_VER . "\n", 'normal' );
    $text->insert( 'end', "Author: Ștefan Suciu\n", 'normal' );
    $text->insert( 'end', "Copyright 2020\n", 'normal' );
    $text->insert( 'end', "GNU General Public License (GPL)\n", 'normal' );
    $text->insert( 'end', 'stefan@s2i2.ro',
        'italic' );
    $text->insert( 'end', "\n\n\n\n\n\n" );
    $text->insert( 'end', "Perl " . $PERL_VERSION . "\n", 'normal' );
    $text->insert( 'end', "Tk v" . $Tk::VERSION . "\n", 'normal' );

    $text->configure( -state => 'disabled' );
    $text->pack(
        -expand => 1,
        -fill   => 'both'
    );
    $dbox->Show();
}

# sub validate_config {
#     my ( $self, $cfname ) = @_;
#     my $cfg_file
#         = catfile( $self->configdir($cfname), 'etc', 'application.yml' );
#     my $cfg_href = $self->config_data_from($cfg_file);
#     my $widgetset   = $cfg_href->{application}{widgetset};
#     my $module_name = $cfg_href->{application}{module};
#     my $module_class = $self->application_class( $widgetset, $module_name );
#     ( my $module_file = "$module_class.pm" ) =~ s{::}{/}g;
#     eval { require $module_file };
#     return $@ ? 0 : 1;
# }

sub DEMOLISH {
    my $log_file = App::Fenix::Config::log_file_name;
    unlink $log_file if -f $log_file && -z $log_file;
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
