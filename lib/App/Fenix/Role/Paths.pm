package App::Fenix::Role::Paths;

# ABSTRACT: role for Fenix configuration paths

use 5.010001;
use utf8;
use Moo::Role;
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

=head3 module_path

Returns a relative path to the main module of a Fenix application.
distribution.

    L<Fenix-Name/lib/Fenix/Tk/App>

=cut

has 'module_path' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        return path( qw(lib App Fenix Tk App) );
    },
);

=head3 module_path_exists

Return true if C<module_path> exists.

=cut

sub module_path_exists {
    my $self = shift;
    my $path = $self->module_path;
    return 1 if $path->is_dir;
    return;
}

=head3 screen_module_path

Return the relative path to the screen modules of a Fenix application.

=cut

has 'screen_module_path' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path( $self->module_path, $self->module );
    },
);

=head3 sharedir

Returns the relative path to the configurations of Fenix applications.

    L<Fenix-Name/share/apps>

=cut

has 'sharedir' => (
    is       => 'ro',
    isa      => Path,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my $dir;
        return path $self->cfpath if $self->cfpath;
        try {
            $dir = dist_dir('Fenix');
        }
        catch {
            $dir = 'share';
        };
        return path $dir;
    },
);

=head3 configdir

Returns the path to the user configurations.

For example:

    L</home/me/.local/share/.fenix/apps>

=cut

has 'configdir' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        my $self = shift;
        my $configpath
            = $self->cfpath
            ? $self->cfpath
            : File::UserConfig->new(
            dist     => 'Fenix',
            sharedir => 'share',
        )->configdir;
        return path $configpath ;
    },
);

=head3 app_path_for

Return the application specific configurations path a specific
subdirectory in L<configdir>, provided as a parameter.

For example with L<etc> as parameter:

    L</home/me/.local/share/.fenix/etc>

=cut

sub app_path_for {
    my ($self, $dir, $mnemo) = @_;
    my $mnemonic = $mnemo || $self->mnemonic;
    die "No parameter provided for 'app_path_for'" unless $dir;
    return path( $self->configdir, 'apps', $mnemonic, $dir )
        if $self->configdir && $mnemonic;
    return;
}

=head3 exists_app_path_for

Returns true if the user configurations path exists.

=cut

sub exists_app_path_for {
    my ($self, $dir) = @_;
    my $path = $self->app_path_for($dir);
    return $path if $path->is_dir;
    return;
}

=head3 framework_path_for

Return the framework (Fenix) configurations path for a specific
subdirectory in L<configdir>, provided as a parameter.

For example with L<etc> as parameter:

    L</home/me/.local/share/.fenix/apps/etc>

=cut

sub framework_path_for {
    my ( $self, $dir ) = @_;
    die "No parameter provided for 'framework_path_for'" unless $dir;
    return path( $self->configdir, $dir )
      if $self->configdir;
    return;
}

=head3 exists_framework_path_for

Returns true if the framework (Fenix) configurations path exists.

=cut

sub exists_framework_path_for {
    my ($self, $dir) = @_;
    my $path = $self->framework_path_for($dir);
    return $path if $path->is_dir;
    return;
}

=head3 dist_path_for

=cut

sub dist_path_for {
    my ($self, $dir, $mnemo) = @_;
    my $mnemonic = $mnemo || $self->mnemonic;
    die "No parameter provided for 'dist_path_for'" unless $dir;
    if ( $self->configdir && $mnemonic ) {
        return path $self->sharedir, $mnemonic, $dir;
    }
    return;
}

=head3 dist_sys_path_for

=cut

sub dist_sys_path_for {
    my ($self, $dir) = @_;
    die "No parameter provided for 'dist_sys_path_for'" unless $dir;
    if ( $self->configdir ) {
        return path 'share', $dir;
    }
    return;
}

=head3 exists_dist_path_for

=cut

sub exists_dist_path_for {
    my ($self, $dir) = @_;
    my $path = $self->dist_path_for($dir);
    return $path if $path->is_dir;
    return;
}

=head3 exists_dist_sys_path_for

=cut

sub exists_dist_sys_path_for {
    my ($self, $dir) = @_;
    my $path = $self->dist_sys_path_for($dir);
    return $path if $path->is_dir;
    return;
}

no Moo::Role;

1;

__END__

=encoding utf8

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
