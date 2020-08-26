package App::Fenix::Config::Paths;

# ABSTRACT: Fenix configuration paths

use 5.010001;
use utf8;
use Moo;
use File::UserConfig;
use Path::Tiny qw(cwd path);
use File::ShareDir qw(dist_dir);
use Try::Tiny;
use App::Fenix::Types qw(
    Path
    Maybe
    Str
);
use namespace::autoclean;

has 'mnemonic' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has 'module_path' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        return path( qw(lib Fenix Tk App) );
    },
);

has 'screen_module_path' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path( $self->module_path, $self->module );
    },
);

has 'dist_sharedir' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        return path( qw(share apps) );
    },
);

has 'configdir' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        my $configdir = File::UserConfig->new(
            dist     => 'Fenix',
            sharedir => 'share',
        )->configdir;
        return path($configdir);
    },
);

sub module_path_exists {
    my $self = shift;
    my $path = $self->module_path;
    return 1 if $path->is_dir;
    return;
}

sub user_path_for {
    my ($self, $dir, $mnemo) = @_;
    my $mnemonic = $mnemo || $self->mnemonic;
    die "No parameter provided for 'user_path_for'" unless $dir;
    return path( $self->configdir, 'apps', $mnemonic, $dir )
        if $self->configdir && $mnemonic;
    return;
}

sub user_sys_path_for {
    my ( $self, $dir ) = @_;
    die "No parameter provided for 'user_sys_path_for'" unless $dir;
    return path( $self->configdir, $dir )
      if $self->configdir;
    return;
}

sub exists_user_path_for {
    my ($self, $dir) = @_;
    return 1 if $self->user_path_for($dir)->is_dir;
    return;
}

sub exists_user_sys_path_for {
    my ($self, $dir) = @_;
    return 1 if $self->user_sys_path_for($dir)->is_dir;
    return;
}

sub dist_path_for {
    my ($self, $dir, $mnemo) = @_;
    my $mnemonic = $mnemo || $self->mnemonic;
    die "No parameter provided for 'dist_path_for'" unless $dir;
    if ( $self->configdir && $mnemonic ) {
        return path $self->dist_sharedir, $mnemonic, $dir;
    }
    return;
}

sub dist_sys_path_for {
    my ($self, $dir) = @_;
    die "No parameter provided for 'dist_sys_path_for'" unless $dir;
    if ( $self->configdir ) {
        return path 'share', $dir;
    }
    return;
}

sub exists_dist_path_for {
    my ($self, $dir) = @_;
    return 1 if $self->dist_path_for($dir)->is_dir;
    return;
}

sub exists_dist_sys_path_for {
    my ($self, $dir) = @_;
    return 1 if $self->dist_sys_path_for($dir)->is_dir;
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERFACE

=head2 ATTRIBUTES

=head3 mnemonic

The name of the directory under L<dist_sharedir>.  By default it is a
lower case of the C<module> attribute.

=head3 module_path

Returns a relative path to the main module of a Fenix application.
distribution.

    L<Fenix-Name/lib/Fenix/Tk/App>

=head3 screen_module_path

Return the relative path to the screen modules of a Fenix application.

=head3 dist_sharedir

Returns the relative path to the configurations of Fenix applications.

    L<Fenix-Name/share/apps>

=head3 configdir

Returns the path to the user configurations.

For example, on my box:

    L</home/user/.local/share/.fenix/apps>

=head2 INSTANCE METHODS

=head3 module_path_exists

Return true if C<module_path> exists.

=head3 relative_path_to_dist

Returns a path relative to the new dist.

=head3 user_path_for

Return the user configurations path.

=head3 user_sys_path_for

=head3 exists_user_path_for

Returns true if the user configurations path exists.

=head3 exists_user_sys_path_for

=head3 dist_path_for

=head3 dist_sys_path_for

=head3 exists_dist_path_for

=head3 exists_dist_sys_path_for

=cut
