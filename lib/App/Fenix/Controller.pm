package App::Fenix::Controller;

# ABSTRACT: The Controller

use feature 'say';
use utf8;
use Moo;
use MooX::HandlesVia; # Data::Perl::Collection::Hash::MooseLike
use Try::Tiny;
use Path::Tiny;
use List::Util qw(any);
use File::Basename;
use Class::Unload;
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
use App::Fenix::Model::Table;
use App::Fenix::State;
use App::Fenix::Refresh;
use App::Fenix::View;
use App::Fenix::Exceptions;
use App::Fenix::Tk::Dialog::Message;
use App::Fenix::Tk::Dialog::Login;

use Data::Dump;

with 'MooX::Log::Any';

=head2 options

An attribute that holds the options instance object.

=cut

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

=head2 config

An attribute that holds the configuration instance object.

=cut

has 'config' => (
    is      => 'ro',
    isa     => FenixConfig,
    lazy    => 1,
    builder => '_build_config',
);

=head2 _build_config

Builder for the configuration instance object.

=cut

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

=head2 model

An attribute tha holds the model instance object.

=cut

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

=head _build_model

Builder for the model instance object.

=cut

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

=head2 view

An attribute tha holds the view instance object.

=cut

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
          notebook
      )
    ],
);

=head _build_view

Builder for the view instance object.

=cut

sub _build_view {
    my $self = shift;
    return App::Fenix::View->new(
        config     => $self->config,
        model      => $self->model,
        controller => $self,
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

=head3 screen_rec_name

The short name of the current screen and configuration.  For example
C<products>, C<orders>, etc.

=cut

# _rscrcls
has 'screen_rec_name' => (
    is  => 'rw',
    isa => Maybe[Str],
);

=head3 screen_rec_class

The class name of the current screen.  For example
C<App::Fenix::Tk::App::Demo::Products>.

=cut

# _rscrobj
has 'screen_rec_class' => (
    is  => 'rw',
    isa => Maybe[Str],
);

# _tblkeys
has '_table_meta' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    default     => sub { {} },
    handles     => {
        get_table  => 'get',
        add_table  => 'set',
        all_tables => 'keys',
        rm_table   => 'delete',
    },
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
        return App::Fenix::Config::Screen->new(
            scrcfg_file => $self->config->screen_config_file_path(
                $self->screen_rec_name
            ),
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
        my $class  = $self->screen_rec_class;
        my $screen = $class->new(
            config  => $self->config,
            scrcfg  => $self->scrcfg,
            toolscr => undef, #$from_tools,
        );
        return $screen;
    },
);

sub scrobj {
    my ( $self, $page ) = @_;
    $page ||= $self->notebook->get_current_page;
    return $self->screen_rec
        if $page eq 'rec'
        and $self->screen_rec;
    return $self->screen_det
        if $page eq 'det'
        and $self->screen_det;
    die "Wrong call to 'scrobj'" unless $page;
    return;
}

sub log_message {
    my ($self, $msg) = @_;
    my $newline = ( $msg =~ /\.\./msg ) ? 0 : 1;
    $self->view->log_message($msg, $newline);
    return;
}

=head3 _init

Show the login dialog, until connected or until a fatal error message
is received from the RDBMS.

=cut

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

sub on_screen_mode_idle {
    my ($self, $rules) = @_;

    # Empty the main controls and TM, if any

    # $self->record_clear;

    # foreach my $tm_ds ( keys %{ $self->scrobj()->get_tm_controls() } ) {
    #     $self->scrobj()->get_tm_controls($tm_ds)->clear_all();
    # }

    $self->controls_state_set($rules);

    $self->notebook->set_page_state( 'det', 'disabled');
    $self->notebook->set_page_state( 'lst', 'normal');

    # Trigger 'on_mode_idle' method in screen if defined
    my $page = $self->notebook->get_current_page;
    say "# page = $page";
    # $self->scrobj($page)->on_mode_idle()
    #     if ( $page eq 'rec' or $page eq 'det' )
    #     and $self->scrobj($page)->can('on_mode_idle');

    return;
}

sub on_screen_mode_add {
    my ($self, $rules) = @_;

    # $self->record_clear;              # empty the main controls and TM
    # $self->tmatrix_set_selected();    # initialize selector

    # foreach my $tm_ds ( keys %{ $self->scrobj()->get_tm_controls() } ) {
    #     $self->scrobj()->get_tm_controls($tm_ds)->clear_all();
    # }

    $self->controls_state_set($rules);

    $self->notebook->set_page_state( 'det', 'disabled' );
    $self->notebook->set_page_state( 'lst', 'disabled' );

    # # Default value for user in screen.  Add 'id_user' value if
    # # 'id_user' control exists in screen
    # my $user_field = 'id_user';              # hardwired user field name
    # my $control_ref = $self->scrobj()->get_controls($user_field);
    # $self->ctrl_write_to( $user_field, $self->cfg->user ) if $control_ref;

    # Trigger 'on_mode_add' method in screen if defined
    my $page = $self->notebook->get_current_page;
    # $self->scrobj($page)->on_mode_add()
    #     if ( $page eq 'rec' or $page eq 'det' )
    #     and $self->scrobj($page)->can('on_mode_add');

    return;
}

sub on_screen_mode_find {
    my ($self, $rules) = @_;

    # Empty the main controls and TM, if any

    # $self->record_clear;

    # foreach my $tm_ds ( keys %{ $self->scrobj->get_tm_controls() } ) {
    #     $self->scrobj()->get_tm_controls($tm_ds)->clear_all();
    # }

    $self->controls_state_set($rules);

    # Trigger 'on_mode_find' method in screen if defined
    my $page = $self->notebook->get_current_page();
    # $self->scrobj($page)->on_mode_find
    #     if ( $page eq 'rec' or $page eq 'det' )
    #     and $self->scrobj($page)->can('on_mode_find');

    return;
}

sub on_screen_mode_edit {
    my ($self, $rules) = @_;

    $self->controls_state_set($rules);

    $self->notebook->set_page_state( 'det', 'normal');
    $self->notebook->set_page_state( 'lst', 'normal');

    # Trigger 'on_mode_edit' method in screen if defined
    my $page = $self->notebook->get_current_page();
    # $self->scrobj($page)->on_mode_edit()
    #     if ( $page eq 'rec' or $page eq 'det' )
    #     and $self->scrobj($page)->can('on_mode_edit');

    return;
}

sub on_screen_mode_sele {
    my $self = shift;

    my $nb = $self->view->get_notebook();
    $self->view->set_page_state( 'det', 'disabled');

    return;
}

sub screen_init_keys {
    my ($self, $page, $scrcfg) = @_;

    #-- Main table on the '$page' page

    my @fields    = keys %{ $self->scrcfg->maintable_columns };
    my @fields_rw = keys %{ $self->scrcfg->maintable_columns_rw };
    my $params    = {
        page      => 'rec',
        display   => 'record',
        keys      => $self->scrcfg->maintable( 'keys', 'name' ),
        table     => $self->scrcfg->maintable('name'),
        view      => $self->scrcfg->maintable('view'),
        fields    => \@fields,
        fields_rw => \@fields_rw,
    };

    # dd $params;
    my $table = App::Fenix::Model::Table->new($params);
    if ( ref $table ) {

        # Register main table object on $page page
        $self->add_table( 'main', $table );
    }

    #-- Dependent tables (TableMatrix)

    return unless $self->scrcfg->has_screen_details;

    my @tms = keys %{ $self->scrcfg->deptable };

    die "The screen configuration for the dependent tables requires a label (for example: 'tm1').\n"
        if any { $_ eq 'columns' } @tms;

    foreach my $tm (@tms) {
        say " - tm: $tm  name : ", $self->scrcfg->deptable_name($tm) if $self->verbose;
        my @fields    = keys %{ $self->scrcfg->deptable_columns($tm) };
        my @fields_rw = keys %{ $self->scrcfg->deptable_columns_rw($tm) };
        my $params    = {
            page      => 'rec',
            display   => 'record',
            keys      => $self->scrcfg->deptable_keys( $tm, 'name' ),
            table     => $self->scrcfg->deptable_name($tm),
            view      => $self->scrcfg->deptable_view($tm),
            fields    => \@fields,
            fields_rw => \@fields_rw,
        };
        # dd $params;
        my $table = App::Fenix::Model::Table->new($params);
        if ( ref $table ) {

            # Register main table object on $page page
            $self->add_table( $tm, $table );
        }
    }

    return;
}

sub controls_state_set {
    my ( $self, $rules ) = @_;

    my $page = $self->notebook->get_current_page;

    return unless $page;

    my $bg = $self->scrobj->get_bgcolor;

    # # Enable controls for report style screen
    # $control_states = $self->control_states('edit')
    #   if $self->scrcfg()->screen('style') eq 'report';

    # return unless defined $self->scrcfg($page);

    dd $rules;

    my @ctrls = $self->screen_rec->all_ctrls;
    foreach my $field ( @ctrls ) {
        my $rec = $self->screen_rec->get_ctrl($field);
        if ( $self->debug ) {
            say "# name = ", $rec->name;
            say "# type = ", $rec->type;
            say "# ctrl = ", $rec->ctrl;
            say "---";
        }

        my $fld_cfg = $self->scrcfg->maintable->{columns}{$field};
        #dd $fld_cfg;

        my $state = $rules->{state};
        $state = $fld_cfg->{state}
            if $state eq 'from_config';

        my $bkground = $rules->{background};
        my $bg_color = $bkground;
        $bg_color = $fld_cfg->{bgcolor}
            if $bkground eq 'from_config';
        $bg_color = $bg
            if $bkground eq 'disabled_bgcolor';

    #     # Special case for find mode and fields with 'findtype' set to none
    #     if ( $set_state eq 'find' ) {
    #         if ( $fld_cfg->{findtype} eq 'none' ) {
    #             $state    = 'disabled';
    #             $bg_color = $self->scrobj($page)->get_bgcolor();
    #         }
    #     }

        # Allow 'bg' as bgcolor config attribute value for controls
        $bg_color = $bg if $bg_color =~ m{bg|background};

        # Configure controls
        my $control = $rec->ctrl;
        if ($control) {
            $self->view->configure_controls( $control, $state,
                $bg_color, $fld_cfg );
        }
        else {
            warn "Can't configure control for '$field'";
        }
    }

    return;
}

=head2 table_meta

Return the table metadata on the $page with $name.

=cut

sub table_meta {
    my ($self, $name) = @_;
    die "table_meta: Unknown 'name' parameter" unless $name;
    return $self->get_table($name);
}

=head2 is_record

Return true if a record is loaded in the main screen.

=cut

sub is_record {
    my $self  = shift;
    my $table = $self->table_meta('main');
    return if !$table or !$table->isa('Fenix::Model::Table');
    return $table->get_key(0)->value;
}

sub is_connected {
    my $self = shift;
    return $self->get_state('conn_state') eq 'connected';
}

=head2 connect_dialog

Show login dialog until connected or canceled.  Called with delay from
XX::Controller.

=cut

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

    #-- Find mode
    $self->view->event_handler_for_tb_button(
        'tb_fm',
        sub { $self->toggle_mode_find }
    );

    #-- Find execute
    $self->view->event_handler_for_tb_button(
        'tb_fe',
        sub { $self->record_find_execute }
    );

    #-- Find count
    $self->view->event_handler_for_tb_button(
        'tb_fc',
        sub { $self->record_find_count }
    );

    #-- Print (preview) default report button
    $self->view->event_handler_for_tb_button(
        'tb_pr',
        sub { $self->screen_report_print }
    );

    #-- Generate default document button
    $self->view->event_handler_for_tb_button(
        'tb_gr',
        sub { $self->screen_document_generate }
    );

    #-- Take note
    $self->view->event_handler_for_tb_button(
        'tb_tn',
        sub { $self->take_note() }
    );

    #-- Restore note
    $self->view->event_handler_for_tb_button(
        'tb_tr',
        sub { $self->restore_note }
    );

    #-- Reload
    $self->view->event_handler_for_tb_button(
        'tb_rr',
        sub { $self->record_reload() }
    );

    #-- Add mode; From sele mode forbid add mode
    $self->view->event_handler_for_tb_button(
        'tb_ad',
        sub { $self->toggle_mode_add() }
    );

    #-- Delete
    $self->view->event_handler_for_tb_button(
        'tb_rm',
        sub { $self->event_record_delete }
    );

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

    #-- Save geometry
    $self->view->event_handler_for_tb_button(
        'tb_at',
        sub { $self->save_geometry }
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

sub toggle_mode_find {
    my $self = shift;

    say "toggle find modified=", $self->model->is_modified ? 'yes' : 'no'
      if $self->debug;

    # if ( $self->model->is_modified ) {
    #     my $answer = $self->ask_to_save;
    #     if ( !defined $answer ) {
    #         $self->view->get_toolbar_btn('tb_fm')->deselect;
    #         return;
    #     }
    # }
    $self->get_mode eq 'find'
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('find');

    #$self->model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                         # undef = unloaded

    $self->view->set_status( '', 'ms' );     # clear messages

    return;
}

sub toggle_mode_add {
    my $self = shift;

    # say "toggle add modified=", $self->model->is_modified ? 'yes' : 'no'
    #   if $self->debug;

    # TODO: implement is_modified
    # if ( $self->model->is_modified ) {
    #     if ( $self->model->get_mode('edit') ) {
    #         my $answer = $self->ask_to_save;
    #         if ( !defined $answer ) {
    #             $self->view->get_toolbar_btn('tb_ad')->deselect;
    #             return;
    #         }
    #     }
    # }
    $self->get_mode eq 'add'
        ? $self->set_app_mode('idle')
        : $self->set_app_mode('add');

    # $self->model->set_scrdata_rec(0);    # false = loaded,  true = modified,
                                         # undef = unloaded

    $self->view->set_status( '', 'ms' );    # clear messages

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

=head2 screen_module_class

Builds and returns the screen module class name in the
L<App::Fenix::Tk::App> name space.  If the $from_tools parameter is
true, uses the tools name space: L<App::Fenix::Tk::Tools>.

=cut

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
    print "# loading >$module<\n" if $self->verbose;
    my $rscrstr = lc $module;
    $self->screen_rec_name($rscrstr);        # set
    say '# screen: ', $self->screen_rec_name;

    # Destroy and recreate record panel widget
    $self->view->record->destroy;
    $self->view->record->reset_panel;
    $self->view->record->make;

    # Unload current screen
    $self->screen_module_unload;

    my $screen_class = $self->require_screen( $module, $from_tools );
    if ($screen_class) {
        $self->screen_rec_class($screen_class);    # set
        say "# class: ", $self->screen_rec_class;
    }
    else {
        say "# NO screen class";
        return;
    }

    $self->reset_scrcfg;
    $self->reset_screen_rec;

    # my $maintable_h = $self->scrcfg->maintable;
    # use Data::Dump; dd $maintable_h;
    $self->log->info("New screen instance: $module");

    return unless $self->check_cfg_version;  # current version is 5

    # Details page
    my $has_det = $self->scrcfg->has_screen_details;
    if ($has_det) {
        say " has details = $has_det";
        # my $lbl_details = __ 'Details';
        # $self->view->create_notebook_panel( 'det', $lbl_details );
        # $self->_set_event_handler_nb('det');
    }
    else {
        say " no details screen";
    }

    # Show screen
    $self->screen_rec->run_screen( $self->view->record );

    $self->screen_rec->register_controls;

    my @ctrls = $self->screen_rec->all_ctrls;
    # dd @ctrls;

    #$self->alter_toolbar_state;

    # # Load instance config
    # $self->cfg->config_load_instance();

    # #-- Lookup bindings for Entry widgets
    # $self->setup_lookup_bindings_entry('rec');
    # $self->setup_select_bindings_entry('rec');

    # #-- Lookup bindings for tables (TableMatrix)
    # $self->setup_bindings_table();

    # Set table metadata
    $self->rm_table( $self->all_tables );     # reset
    $self->screen_init_keys( 'rec', $self->scrcfg );
    my @tables = $self->all_tables;
    foreach my $t (@tables) {
        say "# table: $t  ", $self->get_table($t)->table;
    }

    $self->set_app_mode('idle');

    # List header
    my $header_look = $self->scrcfg->list_header('lookup');
    my $header_cols = $self->scrcfg->list_header('column');
    my $fields      = $self->scrcfg->maintable('columns');
    if ($header_look and $header_cols) {
        $self->view->make_list_header( $header_look, $header_cols, $fields );
    }
    else {
        $self->view->set_page_state( 'lst', 'disabled' );
    }

    # # Toggle find mode menus
    # my $menus_state
    #     = $self->scrcfg()->screen('style') eq 'report'
    #     ? 'disabled'
    #     : 'normal';
    # $self->_set_menus_state($menus_state);

    # $self->view->set_status( '', 'ms' );

    # $self->model->unset_scrdata_rec();

    # # Change application title
    # my $descr = $self->scrcfg->screen('description');
    # $self->view->title(' Tpda3 - ' . $descr) if $descr;

    # Update window geometry
    $self->set_geometry();

    # # Load lists into ComboBox type widgets
    # $self->screen_load_lists();

    # # Trigger on_load_screen method from screen if defined
    # $self->scrobj('rec')->on_load_screen()
    #     if $self->scrobj('rec')->can('on_load_screen');

    say "# screen_module_load: done loading.";

    return 1;                       # to make ok from Test::More happy
}

sub set_mode {
    my ($self, $mode) = @_;
    $self->set_state('gui_state', $mode);
    return;
}

sub get_mode {
    my ($self) = @_;
    return $self->get_state('gui_state');
}

=head2 set_app_mode

Set application mode to $mode.

=cut

sub set_app_mode {
    my ( $self, $mode ) = @_;
    $self->set_mode($mode);
    $self->toggle_interface_controls;
    unless ( $self->screen_rec_class ) {
        say "set_app_mode: No screen_rec_class!";
        return;
    }
    $self->toggle_screen_interface_controls;
    return 1;    # to make ok from Test::More happy
                 # probably missing something :) TODO!
}

sub toggle_interface_controls {
    my $self = shift;

    my $conf = $self->toolbar->config;
    my $mode = $self->get_mode;
    my $page = $self->notebook->get_current_page;
    say "toggle_interface_controls:  page = $page   mode = $mode";
    my $is_rec = $self->is_record;

    foreach my $name ( $conf->all_toolbar_names ) {
        my $status = $conf->get_tool($name)->{state}{$page}{$mode};
        # say "tb: $name -> $status";

        #- Corrections
        unless ( ( $page eq 'lst' ) and $self->{_rscrcls} ) {
            next unless $status;
        }

        #     #-- Restore note

        #     if ( ( $name eq 'tb_tr' ) and ( $status eq 'normal' ) ) {
        #         my $data_file = $self->storable_file_name;
        #         $status = 'disabled' if !-f $data_file;
        #     }

        #     #-- Print preview.

        #     # Activate only if default report configured for screen
        #     if ( ( $name eq 'tb_pr' ) and ( $status eq 'normal' ) ) {
        #         $status = 'disabled' if
        #             !$self->scrcfg('rec')->has_defaultreport;
        #     }

        #     #-- Generate document

        #     # Activate only if default document template configured
        #     # for screen
        #     if ( ( $name eq 'tb_gr' ) and ( $status eq 'normal' ) ) {
        #         $status = 'disabled' if
        #             !$self->scrcfg('rec')->has_defaultdocument;
        #     }
        # }
        # else {
        #     #-- List tab

        #     $status = 'disabled';
        # }

        #- Set status for toolbar buttons

        $self->view->enable_tool( $name, $status );
    }

    return;
}

sub toggle_screen_interface_controls {
    my $self = shift;

    my $page = $self->notebook->get_current_page;
    my $mode = $self->get_mode;

    return if $page eq 'lst';

    #- Toolbar (table)

    # my $group_labels = $self->scrcfg->scr_toolbar_groups;
    # foreach my $label ( @{$group_labels} ) {
    #     say " group labels = $label";
    #     my ( $toolbars, $tb_attrs )
    #         = $self->screen_rec->app_toolbar_names($label);

    #     dd $toolbars;
    #     dd $tb_attrs;
    #     foreach my $button_name ( @{$toolbars} ) {
    #         say $button_name;
    #         say $self->scrcfg->screen('style');
    #         # my $status
    #         #     = $self->scrcfg->screen('style') eq 'report'
    #         #     ? 'normal'
    #         #     : $tb_attrs->{$button_name}{state}{$page}{$mode};
    #         # say " button_name: $button_name -> $status";
    #         # $self->screen_rec->enable_tool( $label, $button_name, $status );
    #     }
    # }
    return;
}

sub set_geometry {
    my $self = shift;
    my $screen_name
        = $self->screen_rec_name
        ? $self->screen_rec_name
        : return;
    my $geom = $self->config->instance->get_screen($screen_name);
    unless ($geom) {
        $geom = $self->scrcfg->scr->{screen}{geometry};
    }
    $self->view->set_geometry($geom);
    return;
}

sub save_geometry {
    my $self = shift;
    my $screen_name = $self->screen_rec_name
        ? $self->screen_rec_name
        : 'main';
    say "# save geometry: $screen_name";
    $self->config->instance->save(
        $screen_name,
        $self->view->get_geometry,
    );
    return;
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
    $text->insert( 'end', "Copyright 2026\n", 'normal' );
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

sub screen_module_unload {
    my $self = shift;
    if ( $self->screen_rec_class ) {
        Class::Unload->unload( $self->screen_rec_class );
        if ( Class::Inspector->loaded( $self->screen_rec_class ) ) {
            $self->log->info("Error unloading '" . $self->screen_rec_class . "' screen");
        }
        else {
            $self->log->info("Unloading '" . $self->screen_rec_class . "' screen");
        }
    }
    return;
}

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
        $self->screen_module_unload;
        return;
    }
    else {
        return 1;
    }
}

=head3 _ctrl_write

Proxy method for C<control_write> from the View class.

=cut

sub _ctrl_write {
    my ($self, $name, $value) = @_;
    my $ctrl = $self->screen_rec->get_ctrl($name);
    if ($ctrl) {
        $self->view->control_write( $ctrl, $value );
    }
    else {
        warn "WW: Control name '$name', not found\n";
    }
    return;
}

=head3 _ctrl_read

Proxy method for C<control_read> from the View class.

=cut

sub _ctrl_read {
    my ($self, $name) = @_;
    my $ctrl = $self->screen_rec->get_ctrl($name);
    return $self->view->control_read($ctrl);
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
    $self->set_state('gui_state', 'init');
    $self->set_state('db_name', $cc->dbname);
    $self->_setup_events;
    $self->_init;
    return;
}

sub DEMOLISH {
    my $log_file = App::Fenix::Config::log_file_name;
    unlink $log_file if -f $log_file && -z $log_file;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 SYNOPSIS

    use App::Fenix::Controller;

    my $controller = App::Fenix::Controller->new();

    $controller->view->MainLoop;

Old variable names:

=over

=item _rscrcls  - class name of the current I<record> screen

=item _rscrobj  - current I<record> screen object

=item _dscrcls  - class name of the current I<detail> screen

=item _dscrobj  - current I<detail> screen object

=item _tblkeys  - record of database table keys and values

=item _scrdata  - current screen data

=back

=head1 DESCRIPTION

=cut
