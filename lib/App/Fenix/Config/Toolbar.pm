package  App::Fenix::Config::Toolbar;

# ABSTRACT: Toolbar configurations

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    Path
);

with qw/App::Fenix::Role::FileUtils
        App::Fenix::Role::Utils/;

has 'toolbar_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
);

has '_toolbar' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_toolbar',
    handles     => {
        get_tool    => 'get',
        all_buttons => 'keys',
    },
);

sub _build_toolbar {
    my $self = shift;
    my $toolbar_file = $self->toolbar_file->stringify;
    my $yaml = $self->load_yaml($toolbar_file);
    return $yaml;
}

has '_toolbar_names' => (
    is          => 'ro',
    handles_via => 'Array',
    lazy        => 1,
    init_arg    => undef,
    handles     => {
        all_toolbar_names => 'elements',
    },
    default => sub {
        my $self = shift;
        my $hash = $self->_build_toolbar;
        return $self->sort_hash_by_id($hash);
    },
);


__PACKAGE__->meta->make_immutable;

1;
