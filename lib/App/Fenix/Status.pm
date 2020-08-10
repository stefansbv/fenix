package App::Fenix::Status;

# ABSTRACT: Statusbar

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    FenixConfig
    TkFrame
    TkStatusbar
);
use Path::Tiny;
use Tk;
use Tk::widgets qw(StatusBar);

has 'frame' => (
    is       => 'ro',
    isa      => TkFrame,
    required => 1,
);

has config => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'status' => (
    is      => 'ro',
    isa     => TkStatusbar,
    lazy    => 1,
    builder => '_build_statusbar',
);

sub _build_statusbar {
    my $self = shift;
    my $sb = $self->frame->StatusBar;

    # Dummy label for left space
    $sb->addLabel(
        -width  => 1,
        -relief => 'flat',
    );

    # First label for various messages
    my $ms = $sb->addLabel( -relief => 'flat' );
    $self->set_comp('ms', $ms);

    # Connection icon
    my $cn = $sb->addLabel(
        -width  => 3,
        -relief => 'raised',
        -anchor => 'center',
        -side   => 'right',
    );
    $self->set_comp('cn', $cn);

    # Database name
    my $db = $sb->addLabel(
        -width      => 13,
        -anchor     => 'center',
        -side       => 'right',
        -background => 'lightyellow',
    );
    $self->set_comp('db', $db);

    # Progress
    $self->{progres} = 0;
    my $pr = $sb->addProgressBar(
        -length     => 100,
        -from       => 0,
        -to         => 100,
        -variable   => \$self->{progres},
        -foreground => 'blue',
    );
    $self->set_comp('pr', $pr);

    # Second label for modified status
    my $ss = $sb->addLabel(
        -width      => 3,
        -relief     => 'sunken',
        -anchor     => 'center',
        -side       => 'right',
        -background => 'lightyellow',
    );
    $self->set_comp('ss', $ss);

    # Mode
    my $md = $sb->addLabel(
        -width      => 4,
        -anchor     => 'center',
        -side       => 'right',
        -foreground => 'blue',
        -background => 'lightyellow',
    );
    $self->set_comp('md', $md);

    return $sb;
}

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
    return $self->status;
}

__PACKAGE__->meta->make_immutable;

1;
