package App::Fenix::Config::Menubar;

# ABSTRACT: Menu configurations from YAML files

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    Path
);

with qw/App::Fenix::Role::FileUtils
        App::Fenix::Role::Utils/;

has 'menubar_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
);

has '_menubar' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_menubar',
    handles     => {
        get_menu  => 'get',
        all_menus => 'keys',
    },
);

sub _build_menubar {
    my $self = shift;
    my $menubar_file = $self->menubar_file->stringify;
    my $yaml  = $self->load_yaml($menubar_file);
    return $yaml;
}

has '_menubar_names' => (
    is          => 'ro',
    handles_via => 'Array',
    lazy        => 1,
    init_arg    => undef,
    handles     => {
        all_menubar_names => 'elements',
    },
    default => sub {
        my $self = shift;
        my $hash = $self->_build_menubar;
        return $self->sort_hash_by_id($hash);
    },
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 menubar_file

=head3 _menubar

=head3 _menubar_names

=head2 INSTANCE METHODS

=head3 _build_menubar

=cut
