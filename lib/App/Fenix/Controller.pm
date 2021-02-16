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
    FenixConfigScr
    FenixModel
    FenixState
    FenixView
    Str
    TkFrame
);

use App::Fenix::X qw(hurl);
use App::Fenix::Options;
use App::Fenix::Config;
use App::Fenix::Config::Screen;
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
    handles => [
        qw(
          toolbar
          menubar
          )
      ],
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

has 'screen_rec_name' => (
    is  => 'rw',
    isa => Maybe[Str],
);

has 'screen_rec_module' => (
    is  => 'rw',
    isa => Maybe[Str],
);

sub require_screen {
    my ( $self, $module, $from_tools ) = @_;
    my ( $class, $module_file ) =
      $self->screen_module_class( $module, $from_tools );
    eval { require $module_file };
    if ($@) {
        print "EE: Can't load '$module_file'\n";
        print " reason: $@\n" if $self->debug;
        return;
    }
    unless ( $class->can('run_screen') ) {
        my $msg = "EE: Screen '$class' can not 'run_screen'";
        print "$msg\n";
        $self->log->error($msg);
        return;
    }
    return $class;
}

has 'scrcfg' => (
    is      => 'ro',
    isa     => FenixConfigScr,
    lazy    => 1,
    clearer => 'reset_scrcfg',
    default => sub {
        my $self = shift;
        return App::Fenix::Config::Screen->new( scrcfg_file =>
              $self->config->screen_config_file_path( $self->screen_rec_name ),
        );
    },
);

has 'screen_rec' => (
    is      => 'ro',
    # isa     => FenixConfigScr,
    lazy    => 1,
    clearer => 'reset_screen_rec',
    default => sub {
        my $self = shift;
        my $class  = $self->screen_rec_module;
        my $screen = $class->new(
            config  => $self->config,
            scrcfg  => $self->scrcfg,
            toolscr => undef, #$from_tools,
        );
        return $screen;
    },
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

    foreach my $item ( @{ $self->menubar->get_app_menu_popup_list } ) {
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
    say "Mnemonics (application configurations):";
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

sub screen_module_class {
    my ( $self, $module, $from_tools ) = @_;
    my $module_class;
    if ($from_tools) {
        $module_class = "App::Fenix::Tk::Tools::${module}";
    }
    else {
        $module_class = $self->config->application_class . "::${module}";
    }
    ( my $module_file = "$module_class.pm" ) =~ s{::}{/}g;
    return ( $module_class, $module_file );
}

sub screen_module_load {
    my ( $self, $module, $from_tools ) = @_;
    print "Loading >$module<\n" if $self->verbose;
    my $rscrstr = lc $module;
    $self->screen_rec_name($rscrstr);        # set
    say '#screen: ', $self->screen_rec_name;

    # Destroy and recreate record panel widget
    $self->view->record->destroy;
    $self->view->record->reset_panel;
    $self->view->record->make;

    my $screen_class = $self->require_screen($module, $from_tools);
    $self->screen_rec_module($screen_class); # set
    say "#class: ", $self->screen_rec_module;
    $self->reset_scrcfg;
    $self->reset_screen_rec;

    # my $maintable_h = $self->scrcfg->maintable;
    # use Data::Dump; dd $maintable_h;
    $self->log->trace("New screen instance: $module");

    return unless $self->check_cfg_version;  # current version is 5

    # # Details page
    # my $has_det = $self->scrcfg('rec')->has_screen_details();
    # if ($has_det) {
    #     my $lbl_details = __ 'Details';
    #     $self->view->create_notebook_panel( 'det', $lbl_details );
    #     $self->_set_event_handler_nb('det');
    # }

    # Show screen
    $self->screen_rec->run_screen( $self->view->record );

    #$self->alter_toolbar_state;

    # # Load instance config
    # $self->cfg->config_load_instance();

    # #-- Lookup bindings for Entry widgets
    # $self->setup_lookup_bindings_entry('rec');
    # $self->setup_select_bindings_entry('rec');

    # #-- Lookup bindings for tables (TableMatrix)
    # $self->setup_bindings_table();

    # # Set Key column names
    # $self->{_tblkeys}{rec} = undef; # reset
    # $self->screen_init_keys( 'rec', $self->scrcfg('rec') );

    # $self->screen_init_details( $self->scrcfg('rec') );

    # $self->set_app_mode('idle');

    # List header
    my $header_look = $self->scrcfg->list_header('lookup');
    my $header_cols = $self->scrcfg->list_header('column');
    my $fields      = $self->scrcfg->maintable('columns');

    if ($header_look and $header_cols) {
        $self->view->make_list_header( $header_look, $header_cols, $fields );
    }
    else {
        $self->view->nb_set_page_state( 'lst', 'disabled' );
    }

    # #- Event handlers
    # my $group_labels = $self->scrcfg()->scr_toolbar_groups();
    # foreach my $label ( @{$group_labels} ) {
    #     $self->set_event_handler_screen($label);
    # }

    # # Toggle find mode menus
    # my $menus_state
    #     = $self->scrcfg()->screen('style') eq 'report'
    #     ? 'disabled'
    #     : 'normal';
    # $self->_set_menus_state($menus_state);

    # $self->view->set_status( '', 'ms' );

    # $self->model->unset_scrdata_rec();

    # # Change application title
    # my $descr = $self->scrcfg('rec')->screen('description');
    # $self->view->title(' Tpda3 - ' . $descr) if $descr;

    # # Update window geometry
    # $self->set_geometry();

    # # Load lists into ComboBox type widgets
    # $self->screen_load_lists();

    # # Trigger on_load_screen method from screen if defined
    # $self->scrobj('rec')->on_load_screen()
    #     if $self->scrobj('rec')->can('on_load_screen');



    return 1;                       # to make ok from Test::More happy
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

sub check_cfg_version {
    my $self = shift;
    my $cfg = $self->scrcfg->screen;
    my $req_ver = 5;            # current screen config version
    my $cfg_ver = ( exists $cfg->{version} ) ? $cfg->{version} : 1;

    unless ( $cfg_ver == $req_ver ) {
        my $screen_name = $self->scrcfg->screen('name');
        my $msg = "Screen configuration ($screen_name.conf) error!\n\n";
          $msg .= "The screen configuration file version is '$cfg_ver' ";
          $msg .= "but the required version is '$req_ver'\n\n";
          $msg .= "Hint: Upgrade Tpda3 to a newer version.\n" if
              $cfg_ver > $req_ver;
        Exception::Config::Version->throw(
            usermsg => $msg,
            logmsg  => "Config version error for '$screen_name.conf'\n",
        );
        if ( $self->{_rscrcls} ) {
            Class::Unload->unload( $self->{_rscrcls} );
            if ( Class::Inspector->loaded( $self->{_rscrcls} ) ) {
                $self->_log->info("Error unloading '$self->{_rscrcls}' screen");
            }
        }
        return;
    }
    else {
        return 1;
    }
}

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

    use App::Fenix::Controller;

    my $controller = App::Fenix::Controller->new();

    $controller->view->MainLoop;

=head2 new

Constructor method.

=over

=item _rscrcls  - class name of the current I<record> screen

=item _rscrobj  - current I<record> screen object

=item _dscrcls  - class name of the current I<detail> screen

=item _dscrobj  - current I<detail> screen object

=item _tblkeys  - record of database table keys and values

=item _scrdata  - current screen data

=back

=head2 _init

Show the login dialog, until connected or until a fatal error message
is received from the RDBMS.

=head1 ATTRIBUTES

=head1 METHODS

=head3 BUILD

=cut
