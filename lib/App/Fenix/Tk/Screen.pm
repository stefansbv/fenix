package App::Fenix::Tk::Screen;

# ABSTRACT: App::Fenix Screen base class

use Carp;
use Moo;
use App::Fenix::Types qw(
    FenixConfig
    FenixConfigScr
    FenixView
    Path
    Str
    TkFrame
);

use App::Fenix::Tk::Entry;
use App::Fenix::Tk::Text; # TODO: check
use App::Fenix::Tk::TB;
use App::Fenix::Config::Screen;

#use App::Fenix::Tk::Validation;

with qw/App::Fenix::Role::DBUtils/;

has config => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'scrcfg' => (
    is       => 'ro',
    isa      => FenixConfigScr,
    required => 1,
);

has 'view' => (
    is       => 'rw',
    #isa      => FenixView,
    required => 0,
);

has 'top' => (
    is       => 'rw',
    isa      => TkFrame,
    required => 0,
);

has 'bg' => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

sub _init {
    my ($self, $args) = @_;

    die "_init: the ..." unless $args;
    $self->top( $args->panel );
    $self->view( $args->view );
    $self->bg( $args->bg_color );

    # my $validation
    #     = App::Fenix::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

    return;
}

sub run_screen {
    my ( $self, $nb ) = @_;
    print 'run_screen not implemented in ', __PACKAGE__, "\n";
    return;
}

sub get_controls {
    my ($self, $field) = @_;

    # croak "'get_controls' not implemented.\n"
    #     unless exists $self->{controls}
    #         and scalar %{ $self->{controls} };

    if ($field) {
        return $self->{controls}{$field};
    }
    else {
        return $self->{controls};
    }
}

sub get_tm_controls {
    my ( $self, $tm_ds ) = @_;

    return {} if !exists $self->{tm_controls};

    if ($tm_ds) {
        ( exists $self->{tm_controls}{$tm_ds} )
            ? ( return ${ $self->{tm_controls}{$tm_ds} } )
            : ( croak "No TM $tm_ds in screen!" );
    }
    else {
        return $self->{tm_controls};
    }
}

sub get_rq_controls {
    my $self = shift;

    return {} if !exists $self->{rq_controls};

    return $self->{rq_controls};
}

sub get_toolbar_btn {
    my ( $self, $tm_ds, $name ) = @_;
    return $self->{tb}{$tm_ds}->get_toolbar_btn($name);
}

sub enable_tool {
    my ( $self, $tm_ds, $btn_name, $state ) = @_;

    die "No ToolBar '$tm_ds' ($btn_name)"
        if not defined $self->{tb}{$tm_ds};

    $self->{tb}{$tm_ds}->enable_tool( $btn_name, $state );

    return;
}

sub get_bgcolor {
    my $self = shift;
    return $self->{bg} // 'white';
}

sub make_toolbar_for_table {
    my $self = shift;
    $self->make_toolbar_in_frame(@_);
    return;
}

sub make_toolbar_in_frame {
    my ( $self, $toolbar, $tb_frame, $tb_opts ) = @_;
    my $yaml_file = path( qw(share apps test-tk etc toolbar.yml) );
    my $side = 'top';
    if (ref $tb_opts eq 'HASH') {
        $side = $tb_opts->{side} if $tb_opts->{side};
    }
    my ($toolbars) = $self->scrcfg->scr_toolbar_names($toolbar);
    my $tb = App::Fenix::Toolbar->new(
        frame        => $tb_frame,
        toolbar_file => $yaml_file,
        side         => $side,
        filter       => $toolbars,
    )->make;
    # $self->{tb}{$toolbar} = $tb_frame->TB(
    #     -movable       => 0,
    #     -side          => $side,
    #     -cursorcontrol => 0,
    # );

    # my $attribs    = $self->app_toolbar_attribs($toolbar);
    # foreach my $name ( @{$toolbars} ) {
    #     $self->{tb}{$toolbar}->make_toolbar_button( $name, $attribs->{$name} );
    # }
    return $tb;
}

sub tmatrix_add_row {
    my ( $self, $tm_ds ) = @_;
    my $tmx = $self->get_tm_controls($tm_ds);
    my $row = $tmx->add_row();
    $self->screen_update($tm_ds, $row, 'add');
    return;
}

sub tmatrix_remove_row {
    my ( $self, $tm_ds ) = @_;
    my $tmx = $self->get_tm_controls($tm_ds);
    my $row = $tmx->get_active_row();
    if ($row) {
        $tmx->remove_row($row);
        $self->screen_update($tm_ds, $row, 'remove');
    }
    return;
}

sub tmatrix_renumber_rows {
    my ( $self, $tm_ds ) = @_;
    my $tmx = $self->get_tm_controls($tm_ds);
    $tmx->renum_row();
    $self->screen_update($tm_ds, 'all_rows', 'renumber');
    return;
}

sub date_format {
    my $self = shift;
    return $self->config->application_dateformat;
}

sub app_toolbar_attribs {
    my $self = shift;
    return $self->config->toolbar2;
}

sub app_toolbar_names {
    my ($self, $name) = @_;
    my ($toolbars) = $self->scrcfg->scr_toolbar_names($name);
    my $attribs    = $self->app_toolbar_attribs;
    return ( $toolbars, $attribs );
}

sub screen_update {
    my $self = shift;
    return;
}

sub toolscr {
    my $self = shift;
    # load class is App::Fenix::Tk::Tools::${module}
    return $self->{toolscr};
}

1;

=head1 SYNOPSIS

    use base 'App::Fenix::Tk::Screen';

    sub run_screen {
        my ( $self, $nb ) = @_;

        my $rec_page = $nb->page_widget('rec');
        my $det_page = $nb->page_widget('det');
        $self->{view} = $nb->toplevel;
        $self->{bg}   = $self->{view}->cget('-background');

        my $validation
            = App::Fenix::Tk::Validation->new( $self->{scrcfg}, $self->{view} );

        #-- Frame1 - Customer

        my $frame1 = $rec_page->LabFrame(
            -label      => 'Customer',
            -foreground => 'blue',
            -labelside  => 'acrosstop',
        )->pack;

        # Fields

        my $lcustomername = $frame1->Label( -text => 'Customer' );
        ...

        my $ecustomername = $frame1->MEntry(
            -width    => 35,
            -validate => 'key',
            -vcmd     => sub {
                $validation->validate_entry( 'customername', @_ );
            },
        );
        ...

        # Entry objects: var_asoc, var_obiect
        # Other configurations in '<screen>.conf'
        $self->{controls} = {
            customername     => [ undef, $ecustomername ],
            customernumber   => [ undef, $ecustomernumber ],
            ...
        };
    }

=head2 new

Constructor method.

=head2 run_screen

The screen layout.

=head2 get_controls

Get a data structure containing references to the widgets.

=head2 get_tm_controls

Get a data structure containing references to table matrix widgets.
If TM Id parameter is provided return a reference to that TM object.

=head2 get_rq_controls

Get a HoA reference data structure with the field names that are
required to have values as keys and labels as values.

Usually all fields from the table marked in the I<SQL> structure as
I<NOT NULL>.

=head2 get_toolbar_btn

Return a toolbar button when we know its name.

=head2 enable_tool

Toggle tool bar button.  If state is defined then set to state do not
toggle.  State can come as 0 | 1 and normal | disabled.

=head2 get_bgcolor

Return the background color of the main window.

Must be setup like this in run_screen method of every screen

 my $gui     = $inreg_p->toplevel;
 $self->{bg} = $gui->cget('-background');

=head2 make_toolbar_for_table

Make toolbar for TableMatrix widget, usually with I<add> and I<remove>
buttons.

=head2 tmatrix_add_row

Add new row to the Tk::TableMatrix widget.

=head2 tmatrix_remove_row

Remove row to the Tk::TableMatrix widget.

=head2 app_toolbar_names

Configuration for toolbar buttons.

Get Toolbar names as array reference from screen config.

=head2 screen_update

Update method. To be overridden in the screen module.

Now called only by L<tmatrix_add_row> and L<tmatrix_remove_row>
methods.

=head2 toolscr

Return the toolscr variable.

=cut
