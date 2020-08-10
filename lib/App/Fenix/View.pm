package App::Fenix::View;

# ABSTRACT: The View

use 5.010;
use utf8;
use Moo;
use Scalar::Util qw(blessed);
use App::Fenix::Types qw(
    FenixConfig
    FenixModel
    FenixMenubar
    FenixToolbar
    TkFrame
    FenixPanel
    FenixNotebook
    FenixStatus
);
use Tk;
use App::Fenix::X qw(hurl);
use App::Fenix::Menubar;
use App::Fenix::Toolbar;
use App::Fenix::Notebook;
use App::Fenix::Status;
use App::Fenix::Panel::Initial;
use App::Fenix::Panel::Logger;

# Main window

has config => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'frame' => (
    is      => 'ro',
    isa     => TkFrame,
    lazy    => 1,
    builder => '_build_frame',
);

sub _build_frame {
    my $self = shift;
    my $mw = MainWindow->new;
    return $mw;
}

has 'menu_bar' => (
    is      => 'ro',
    isa     => FenixMenubar,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Menubar->new(
            frame  => $self->frame,
            config => $self->config,
        );
    },
);

has 'tool_bar' => (
    is      => 'ro',
    isa     => FenixToolbar,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Toolbar->new(
            frame  => $self->frame,
            config => $self->config,
        );
    },
);

has 'status' => (
    is      => 'ro',
    isa     => FenixStatus,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Status->new(
            frame  => $self->frame,
            config => $self->config,
        );
    },
);

# Notebooks

has 'notebook' => (
    is      => 'ro',
    isa     => FenixNotebook,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Notebook->new(
            frame  => $self->frame,
            config => $self->config,
        );
    },
);

has 'model' => (
    is      => 'ro',
    isa     => FenixModel,
    lazy    => 1,
    default => sub {
        shift->app->model;
    },
);

has 'input_panel' => (
    is      => 'ro',
    # isa     => FenixPanel,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $pane = App::Fenix::Panel::Initial->new(
            view   => $self,
        );
        return $pane;
    },
);

has 'logger_panel' => (
    is      => 'ro',
    # isa     => FenixPanel,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $pane = App::Fenix::Panel::Logger->new(
            view => $self,
        );
        return $pane;
    },
);

#---

sub event_handler_for_menu {
    my ( $self, $name, $calllback ) = @_;
    $self->menu_bar->get_menu_popup_item($name)->configure( -command => $calllback );
    return;
}

sub event_handler_for_tb_button {
    my ( $self, $name, $calllback ) = @_;
    $self->tool_bar->get_toolbar_btn($name)->configure( -command => $calllback );
    return;
}

sub event_handler_for_key {
    my ( $self, $key, $calllback ) = @_;
    $self->frame->bind(
        $key => sub { $self->$calllback }
    );
    return;
}

sub event_handler_for_notebook {
    my ( $self, $page, $calllback ) = @_;
    $self->notebook->_set_event_handler_nb($page, $calllback);
    return;
}

sub set_status {
    my ( $self, $text, $sb_id, $color ) = @_;

    $sb_id //= 'ms';
    my $sb_label = $self->status->get_comp($sb_id);

    return unless ( $sb_label and $sb_label->isa('Tk::Label') );

    $sb_label->configure( -text       => $text )  if defined $text;
    $sb_label->configure( -foreground => $color ) if defined $color;

    return;
}

sub log_message {
    my ( $self, $message ) = @_;
    my $control = $self->logger_panel->get_ctrl('logger');
    $self->control_write_t( $control->ctrl, $message, 'append' );
    $control->ctrl->see('end');
    return;
}

=head2 control_write

Run the appropriate sub according to control (entry widget) type.

=cut

sub control_write {
    my ($self, $control, $value, $state) = @_;
    my $ctrltype = $control->type;
    my $ctrlname = $control->name;
    my $sub_name = qq{control_write_$ctrltype};
    if ( $self->can($sub_name) ) {
        $self->$sub_name($control->ctrl, $value, $state);
    }
    else {
        print "WW: No '$ctrltype' ctrl type for writing '$ctrlname'!\n";
    }
    return;
}

=head2 control_write_e

Write to a Tk::Entry widget.  If I<$value> not true, than only delete.

=cut

sub control_write_e {
    my ( $self, $control, $value ) = @_;
    my $state = $control->cget ('-state');
    $control->configure( -state => 'normal' );
    $control->delete( 0, 'end' );
    $control->insert( 0, $value ) if $value;
    $control->configure( -state => $state );
    return;
}

=head2 control_write_t

Write to a Tk::Text widget.  If I<$value> not true, than only delete.

=cut

sub control_write_t {
    my ( $self, $control, $value, $is_append ) = @_;
    my $state = $control->cget ('-state');
    $value = q{} unless defined $value;    # empty
    $control->configure( -state => 'normal' );
    $control->delete( '1.0', 'end' ) unless $is_append;
    if ($value) {
        $control->insert( 'end', $value );
        $control->insert( 'end', "\n" ) if $is_append;
    }
    $control->configure( -state => $state );
    return;
}

=head2 control_read

Run the appropriate sub according to control (entry widget) type.

=cut

sub control_read {
    my ($self, $control) = @_;
    my $ctrltype = $control->type;
    my $ctrlname = $control->name;
    my $sub_name = qq{control_read_$ctrltype};
    if ( $self->can($sub_name) ) {
        return $self->$sub_name($control->ctrl, $control->name);
    }
    else {
        print "WW: No '$ctrltype' ctrl type for reading '$ctrlname'!\n";
        return;
    }
}

sub control_read_m {
    my ( $self, $control, $name ) = @_;
    unless ( blessed $control and $control->isa('Tk::JComboBox') ) {
        warn qq(Widget for reading combobox '$name' not found\n);
        return;
    }
    # my $idx = $control->getSelectedIndex;
    # my $val = $control->getSelectedValue;
    # print "$name -> $val\n";
    return $control->getSelectedValue;
}

sub control_read_e {
    my ( $self, $control, $name ) = @_;
    unless ( blessed $control and $control->isa('Tk::Entry') ) {
        warn qq(Widget for reading entry '$name' not found\n);
        return;
    }
    return $control->get;
}

sub control_read_t {
    my ( $self, $control, $name ) = @_;
    unless ( blessed $control and $control->isa('Tk::Frame') ) {
        warn qq(Widget for reading text '$name' not found\n);
        return;
    }
    return $control->get( '0.0', 'end' );
}

sub set_control_state {
    my ( $self, $state, $rules ) = @_;
    # $self->set_status( $state, 'md' );
    return;
}

sub dialog_file {
    my ($self, $initdir, $types) = @_;
    my $path = $self->frame->getOpenFile(
        -title      => 'Choose a file',
        -filetypes  => $types,
        -initialdir => $initdir,
    );
    return $path;
}

sub dialog_path {
    my ($self, $initdir) = @_;
    my $path = $self->frame->chooseDirectory(
        -title      => 'Choose a directory',
        -initialdir => $initdir,
    );
    return $path;
}

sub set_tb_buton_state {
    my ($self, $btn, $state) = @_;
    $self->tool_bar->set_tool_state($btn, $state);
    return;
}

sub BUILD {
    my ( $self, @params ) = @_;

    $self->frame;

    # Load resource file, if found
    my $xres = $self->config->xresource;
    if ($xres->is_file) {
        $self->frame->optionReadfile( $xres->stringify, 'widgetDefault' );
    }
    else {
        warn "WW: Resource not found: '$xres'\n";
    }

    $self->menu_bar->make;
    $self->tool_bar->make;
    $self->status->make;
    #$self->input_panel->make;
    $self->notebook->make;
    $self->logger_panel->make;

    return $self;
}

#-- Quit

sub on_close_window {
    my $self = shift;
    $self->frame->destroy();
    return;
}

1;
