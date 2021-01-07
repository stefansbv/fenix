package App::Fenix::Notebook;

# ABSTRACT: Panel

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    FenixConfig
    TkFrame
    TkNB
    Str
);
use Path::Tiny;
use Tk;
use Tk::widgets qw(LabFrame NoteBook MListbox);
use Locale::TextDomain 1.20 qw(App-Fenix);

has 'frame' => (
    is       => 'ro',
    isa      => TkFrame,
    required => 1,
);

# has config => (
#     is       => 'ro',
#     isa      => FenixConfig,
#     required => 1,
# );

has 'nb' => (
    is      => 'ro',
    isa     => TkNB,
    lazy    => 1,
    builder => '_build_nb',
);

has 'page_curr' => (
    is      => 'rw',
    isa     => Str,
    default => sub { '' },
);

has 'page_prev' => (
    is      => 'rw',
    isa     => Str,
    default => sub { '' },
);

sub _build_nb {
    my $self = shift;

    my $nb = $self->frame->NoteBook->pack(
        -side   => 'top',
        -expand => 1,
        -fill   => 'both',
        -padx   => 3,
        -pady   => 3,
        -ipadx  => 6,
        -ipady  => 6
    );

    #-- Tk::NoteBook Panels

    my $rec = $nb->add(
        'rec',
        -label     => "Record",
        -underline => 0
    );
    $self->set_comp('rec', $rec);

    my $lst = $nb->add(
        'lst',
        -label     => "List",
        -underline => 0
    );
    $self->set_comp('lst', $lst);

    my $det = $nb->add(
        'det',
        -label     => "Details",
        -underline => 0
    );
    $self->set_comp('det', $det);

    return $nb;
}

#---

has 'list' => (
    is      => 'ro',
    #isa     => TkMListbox,
    lazy    => 1,
    builder => '_build_list',
);

sub _build_list {
    my $self = shift;
    my $panel = $self->get_comp('lst');
    my $frm_box = $panel->LabFrame(
        -foreground => 'blue',
        -label      => __ 'Search results',
        -labelside  => 'acrosstop'
    )->pack( -expand => 1, -fill => 'both' );

    my $rc = $frm_box->Scrolled(
        'MListbox',
        -scrollbars         => 'se',
        -background         => 'white',
        -textwidth          => 10,
        -highlightthickness => 2,
        -width              => 0,
        -selectmode         => 'browse',
        -relief             => 'sunken',
        -columns            => [ [qw/-text Nul -textwidth 10/] ]
    );
    $rc->pack( -expand => 1, -fill => 'both' );

    $self->set_comp('rc', $rc);

    return $rc;
}

#---

has '_components' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    default     => sub { {} },
    handles     => {
        get_comp  => 'get',
        set_comp  => 'set',
        all_comps => 'keys',
    },
);

sub make {
    my $self = shift;
    my $nb = $self->nb;
    $self->list;
    return $nb;
}

sub rename_panel {
    my ($self, $p, $name) = @_;
    return $self->nb->pageconfigure($p, '-label' => $name );
}

#--  Notebook methods

sub nb_set_page_state {
    my ($self, $p, $state) = @_;
    $self->nb->pageconfigure( $p, -state => $state );
    return;
}

sub get_nb_current_page {
    my $self = shift;
    return $self->raised;
}

sub set_nb_current {
    my ( $self, $p ) = @_;
    $self->page_prev( $self->page_curr );
    $self->page_curr($p);
    $self->nb->raise($p);
    return $p;
}

sub get_nb_previous_page {
    my $self = shift;
    return $self->page_prev;
}

sub _set_event_handler_nb {
    my ( $self, $p, $callback ) = @_;
    $self->nb->pageconfigure(
        $p,
        -raisecmd => sub {
            $self->set_nb_current($p);

        #-- On page activate

        SWITCH: {
                $p eq 'rec'
                    && do { $self->$callback; last SWITCH; };
                $p eq 'lst'
                    && do { $self->$callback; last SWITCH; };
                $p eq 'det'
                    && do { $self->$callback; last SWITCH; };
                print "EE: \$page is not in (rec lst det)\n";
            }
        },
    );
    return;
}

__PACKAGE__->meta->make_immutable;

1;
