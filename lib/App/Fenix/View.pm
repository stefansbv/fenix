package App::Fenix::View;

# ABSTRACT: The View

use 5.010;
use utf8;
use Moo;
use Scalar::Util qw(blessed);
use App::Fenix::Types qw(
    Bool
    FenixConfig
    FenixMenubar
    FenixModel
    FenixNotebook
    FenixPanel
    FenixStatusbar
    FenixToolbar
    Int
    TkFrame
);
use Tk;
use Tk::Font;
use Tk::widgets qw(MsgBox);

with 'App::Fenix::Role::Utils';

use App::Fenix::X qw(hurl);
use App::Fenix::Menubar;
use App::Fenix::Toolbar;
use App::Fenix::Notebook;
use App::Fenix::Tk::Statusbar;
use App::Fenix::Panel::Initial;
use App::Fenix::Panel::Logger;
use App::Fenix::Panel::Record;

# Main window

has config => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'verbose' => (
    is      => 'ro',
    isa     => Bool,
    default => sub {
        my $self = shift;
        return $self->config->verbose;
    },
);

has 'debug' => (
    is      => 'ro',
    isa     => Bool,
    default => sub {
        my $self = shift;
        return $self->config->debug;
    },
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

# temporizer
has '_tset' => (
    is      => 'rw',
    isa     => Int,
    default => sub {0},
);

has 'menubar' => (
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

has 'toolbar' => (
    is      => 'ro',
    isa     => FenixToolbar,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Toolbar->new(
            frame        => $self->frame,
            toolbar_file => $self->config->toolbar_file,
        );
    },
);

has 'statusbar' => (
    is      => 'ro',
    isa     => FenixStatusbar,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Tk::Statusbar->new(
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

has 'record' => (
    is      => 'ro',
    # isa     => FenixPanel,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $pane = App::Fenix::Panel::Record->new(
            view     => $self,
            nb_frame => $self->notebook->get_comp('rec'),
        );
        #$self->notebook->rename_panel('p1', $pane->name );
        return $pane;
    },
);

#---

sub event_handler_for_menu {
    my ( $self, $name, $calllback ) = @_;
    $self->menubar->get_menu_popup_item($name)->configure( -command => $calllback );
    return;
}

sub event_handler_for_tb_button {
    my ( $self, $name, $calllback ) = @_;
    $self->toolbar->get_btn($name)->configure( -command => $calllback );
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
    my $sb_label = $self->statusbar->get_comp($sb_id);

    return unless ( $sb_label and $sb_label->isa('Tk::Label') );

    if ( $sb_id eq 'cn' ) {
        $sb_label->configure( -image => $text ) if defined $text;
    }
    elsif ( $sb_id eq 'ss' ) {
        my $str = !defined $text ? ''
            : $text          ? 'M'
            :                  'S';
        $sb_label->configure( -text => $str ) if defined $str;
    }
    elsif ( $sb_id eq 'ms' ) {
        $sb_label->configure( -text       => $text )  if defined $text;
        $sb_label->configure( -foreground => $color ) if defined $color;
        $self->temporized_clear($text) if $text; # in not a 'clear'
    }
    else {
        $sb_label->configure( -text       => $text )  if defined $text;
        $sb_label->configure( -foreground => $color ) if defined $color;
    }
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
    $self->set_status( $state, 'md' );
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
    $self->toolbar->set_state($btn, $state);
    return;
}

sub BUILD {
    my ( $self, $args ) = @_;
    $self->frame;

    # Load resource file, if found
    my $xres = $self->config->xresource;
    say "Resource file: $xres" if $self->debug;
    if ( $xres->is_file ) {
        say "Loading resource file: $xres" if $self->debug;
        $self->frame->optionReadfile( $xres->stringify, 'widgetDefault' );
    }
    else {
        warn "WW: Resource not found: '$xres'\n";
    }

    $self->menubar->make;
    $self->toolbar->make;
    $self->statusbar->make;

    #$self->input_panel->make;
    $self->notebook->make;
    $self->logger_panel->make;

    #$self->record->make;

    $self->set_status( 'connectno16', 'cn' );
    $self->get_geometry;
    # $self->set_geometry_main;

    return;
}

sub get_geometry {
    my $self = shift;
    my $win  = $self->frame;
    my $wsys = $win->windowingsystem;
    my $name = $win->name;
    my $geom = $win->geometry;

    # All dimensions are in pixels.
    my $sh = $win->screenheight;
    my $sw = $win->screenwidth;
    say "---";
    print "# system   = $wsys\n";
    print "# name     = $name\n";
    print "# geometry = $geom\n";
    print "# screen   = $sw x $sh\n";
    say "---";
    return $geom;
}

sub set_geometry_main {
    my $self = shift;

    # $self->cfg->config_load_instance();
    my $geom;
    # if ( $self->cfg->can('geometry') ) {
    #     my $go = $self->cfg->geometry();
    #     if (exists $go->{main}) {
    #         $geom = $go->{main};
    #     }
    # }
    unless ($geom) {
        $geom = '800x600+20+20';              # default geom
    }
    $self->frame->geometry($geom);
    return;
}

sub temporized_clear {
    my $self = shift;
    return if $self->_tset == 1;
    $self->frame->after(
        50000,    # miliseconds
        sub {
            $self->set_status( '', 'ms' );
            $self->_tset(0);
        }
    );
    $self->_tset(1);
    return;
}

#--- List page

sub get_recordlist {
    my $self = shift;
    return $self->notebook->get_comp('rc');
}

sub make_list_header {
    my ( $self, $header_look, $header_cols, $fields ) = @_;

    #- Delete existing columns
    $self->get_recordlist->selectionClear( 0, 'end' );
    $self->get_recordlist->columnDelete( 0, 'end' );

    #- Make header
    $self->{lookup} = [];
    my $colcnt = 0;

    #-- For lookup columns

    foreach my $col ( @{$header_look} ) {
        $self->list_header( $fields->{$col}, $colcnt );

        # Save index of columns to return (and the column name)
        push @{ $self->{lookup} }, { $colcnt => $col };

        $colcnt++;
    }

    #-- For the rest of the columns

    foreach my $col ( @{$header_cols} ) {
        $self->list_header( $fields->{$col}, $colcnt );
        $colcnt++;
    }

    return;
}

sub list_header {
    my ( $self, $colattr, $colcnt ) = @_;

    my $label = $self->decode_unless_utf($colattr->{label});

    # Label
    $self->get_recordlist->columnInsert( 'end', -text => $label );

    # Background
    $self->get_recordlist->columnGet($colcnt)->Subwidget('heading')
        ->configure( -background => 'tan' );

    # Width
    $self->get_recordlist->columnGet($colcnt)->Subwidget('heading')
        ->configure( -width => $colattr->{displ_width} );

    # Sort order, (A)lpha is default
    if ( defined $colattr->{datatype} ) {
        if (   $colattr->{datatype} eq 'integer'
            or $colattr->{datatype} eq 'numeric' )
        {
            $self->get_recordlist->columnGet($colcnt)
                ->configure( -comparecommand => sub { $_[0] <=> $_[1] } );
        }
    }
    else {
        print "WW: No 'datatype' attribute for '$label'\n";
    }

    return;
}

sub list_init {
    my $self = shift;
    $self->get_recordlist->selectionClear( 0, 'end' );
    $self->get_recordlist->delete( 0, 'end' );
    return;
}

sub list_populate {
    my ( $self, $ary_ref ) = @_;

    return unless ref $ary_ref eq 'ARRAY';

    my $row_count;

    if ( Exists( $self->get_recordlist ) ) {
        eval { $row_count = $self->get_recordlist->size(); };
        if ($@) {
            warn "Error: $@";
            $row_count = 0;
        }
    }
    else {
        warn "No MList!\n";
        return;
    }

    my $record_count = scalar @{$ary_ref};

    my $list = $self->get_recordlist();

    # Data
    foreach my $record ( @{$ary_ref} ) {
        my @record = map { $self->decode_unless_utf($_) } @$record;
        $list->insert( 'end', \@record );
        $list->see('end');
        $row_count++;
        $list->update;

        # Progress bar
        my $p = floor( $row_count * 10 / $record_count ) * 10;
        if ( $p % 10 == 0 ) { $self->{progres} = $p; }
    }

    # Activate and select last
    $list->selectionClear( 0, 'end' );
    $list->activate('end');
    $list->selectionSet('end');
    $list->see('active');
    $self->{progres} = 0;

    return $record_count;
}

sub list_raise {
    my $self = shift;
    $self->{_nb}->raise('lst');
    $self->get_recordlist->focus;
    return;
}

sub has_list_records {
    my $self = shift;

    my $row_count;

    if ( Exists( $self->get_recordlist ) ) {
        eval { $row_count = $self->get_recordlist->size(); };
        if ($@) {
            warn "Error: $@";
            $row_count = 0;
        }
    }
    else {
        warn "Error, List doesn't exists?\n";
        $row_count = 0;
    }

    return $row_count;
}

sub list_read_selected {
    my $self = shift;

    return unless $self->has_list_records;   # no records

    my @selected;
    my $indecs;

    eval { @selected = $self->get_recordlist->curselection(); };
    if ($@) {
        warn "Error: $@";

        # $self->refresh_sb( 'll', 'No record selected' );
        return;
    }
    else {
        $indecs = pop @selected;    # first row in case of multiselect
        if ( !defined $indecs ) {

            # Activate the last row
            $indecs = 'end';
            $self->get_recordlist->selectionClear( 0, 'end' );
            $self->get_recordlist->activate($indecs);
            $self->get_recordlist->selectionSet($indecs);
            $self->get_recordlist->see('active');
        }
    }

    # 'lookup' is an arrayref and holds the return column: index => name
    my @idxs;
    push @idxs, keys %{$_} foreach @{ $self->{lookup} };

    my @returned;
    # In scalar context, getRow returns the value of column 0
    eval { @returned = ( $self->get_recordlist->getRow($indecs) )[@idxs]; };
    if ($@) {
        warn "Error: $@";
        return;
    }
    else {
        @returned = $self->trim(@returned) if @returned;
    }

    my %selected;
    foreach my $lookup ( @{ $self->{lookup} } ) {
        foreach my $idx ( keys %{$lookup} ) {
            my $field = $lookup->{$idx};
            $selected{$field} = $returned[$idx];
        }
    }

    return \%selected;
}

sub list_remove_selected {
    my ( $self, $keys ) = @_;

    my $sel = $self->list_read_selected();
    if ( !ref $sel ) {
        print "EE: Nothing selected!, use brute force? :)\n";
        return;
    }

    my $dc   = Data::Compare->new($sel, $keys);
    my $same = $dc->Cmp ? 1 : 0;
    unless ($same) {
        print "EE: No matching list row!\n";
        return;
    }

    #- OK, found, delete from list

    my @selected;
    eval { @selected = $self->get_recordlist->curselection(); };
    if ($@) {
        warn "Error: $@";
        return;
    }
    else {
        my $indecs = pop @selected;    # first row in case of multiselect
        if ( defined $indecs ) {
            $self->get_recordlist->delete($indecs);
        }
        else {
            print "EE: Nothing selected!\n";
        }
    }

    return;
}

sub list_locate {
    my ( $self, $pk_val, $fk_val ) = @_;

    my $pk_idx = $self->{lookup}[0];    # indices for Pk and Fk cols
    my $fk_idx = $self->{lookup}[1];
    my $idx;

    my @returned = $self->get_recordlist->get( 0, 'end' );
    my $i = 0;
    foreach my $rec (@returned) {
        if ( $rec->[$pk_idx] eq $pk_val ) {

            # Check fk, if defined
            if ( defined $fk_idx ) {
                if ( $rec->[$fk_idx] eq $fk_val ) {
                    $idx = $i;
                    last;    # found!
                }
            }
            else {
                $idx = $i;
                last;        # found!
            }
        }

        $i++;
    }
    return $idx;
}

#--- End page list

#-- Quit

sub on_close_window {
    my $self = shift;
    $self->frame->destroy();
    return;
}

1;
