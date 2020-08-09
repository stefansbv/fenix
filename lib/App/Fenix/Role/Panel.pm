package App::Fenix::Role::Panel;

# ABSTRACT: Panel role

use Moo::Role;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    FenixConfig
    TkFrame
);
use namespace::autoclean;

# has config => (
#     is       => 'ro',
#     isa      => FenixConfig,
#     required => 1,
# );

has '_controls' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    default     => sub { {} },
    handles     => {
        get_ctrl  => 'get',
        add_ctrl  => 'set',
        all_ctrls => 'keys',
    },
);

has 'panel' => (
    is      => 'ro',
    isa     => TkFrame,
    lazy    => 1,
    builder => '_build_panel',
);

sub _build_panel {
    my $self = shift;
    die "_build_panel not implemented";
    return;
}

sub make {
    my $self = shift;
    return $self->panel;
}

1;
