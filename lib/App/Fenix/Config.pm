package App::Fenix::Config;

# ABSTRACT: A TkConfig Extension

use feature 'say';
use utf8;
use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    Bool
    Maybe
    Path
    Str
    FenixConfigMain
    FenixConfigConn
    FenixConfigApp
);
use Path::Tiny;
use Try::Tiny;
use File::HomeDir;
use Locale::TextDomain 1.20 qw(App-Fenix);
use App::Fenix::X qw(hurl);
use App::Fenix::Config::Connection;
use App::Fenix::Config::Main;
use App::Fenix::Config::Application;
use namespace::autoclean;

with 'App::Fenix::Role::Paths';

#-- required

=head3 mnemonic

The name of the directory under L<sharedir>.  By default it is a
lower case of the C<module> attribute.

=cut

has 'mnemonic' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

has 'user' => (
    is       => 'rw',
    isa      => Maybe[Str],
);

has 'password' => (
    is       => 'rw',
    isa      => Maybe[Str],
);

has 'cfpath' => (
    is       => 'ro',
    isa      => Maybe[Str],
);

#-- optional

has 'verbose' => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);

has 'debug' => (
    is      => 'rw',
    isa     => Bool,
    default => sub {0},
);

#-- hardcoded

# cfgmain
has 'main_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->framework_path_for('etc'), 'main.yml';
    },
);

# cfgdefa
has 'default_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->framework_path_for('etc'), 'default.yml';
    },
);

has 'menubar_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->framework_path_for('etc'), 'menubar.yml';
    },
);

has 'app_menubar_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->app_path_for('etc'), 'menu.yml';
    },
);

has 'toolbar_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->framework_path_for('etc'), 'toolbar.yml';
    },
);

has 'xresource' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->framework_path_for('etc'), 'xresource.xrdb';
    },
);

has 'main' => (
    is      => 'ro',
    isa     => FenixConfigMain,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $main_yml = $self->main_file;
        say "# main_yml = $main_yml";
        return App::Fenix::Config::Main->new( main_file => $main_yml );
    },
    handles => [ 'get_apps_exe_path', 'get_resource_path', ],
);

has 'connection_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->app_path_for('etc'), 'connection.yml';
    },
);

has 'connection' => (
    is      => 'ro',
    isa     => FenixConfigConn,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Config::Connection->new(
            connection_file => $self->connection_file,
        );
    },
);
# handles => [ 'get_apps_exe_path', 'get_resource_path', ],

has 'application_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->app_path_for('etc'), 'application.yml';
    },
);

has 'application' => (
    is      => 'ro',
    isa     => FenixConfigApp,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Config::Application->new(
            application_file => $self->application_file,
        );
    },
);

has 'log_file_path' => (
    is       => 'ro',
    isa      => Path,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return path( $ENV{FENIX_LOG_CONFIG} ) if $ENV{FENIX_LOG_CONFIG};
        return path( $self->framework_path_for('etc'), 'log.conf' );
    },
);

has 'log_file_name' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path( File::HomeDir->home, 'fenix.log' )->stringify;
    },
);

sub application_dateformat {
    my $self = shift;
    say  $self->application->get_application('dateformat');
    return $self->application->get_application('dateformat') || 'iso';
}

sub application_class {
    my ( $self, $module ) = @_;
    $module ||= $self->application->get_application('module');
    return qq{App::Fenix::Tk::App::${module}};
}

sub screen_config_file_path {
    my ( $self, $name ) = @_;
    die "screen_config_file_path: screen config name is required!" unless $name;
    my $file_name = "$name.conf"; # unless $type; # defaults to .conf
    my $file_path = $self->app_path_for('scr');
    my $scr_file  = path $file_path, $file_name;
    if ( $scr_file->is_file ) {
        return $scr_file;
    }
    else {
        die "screen config file '$file_name' not found in '$file_path'";
    }
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

=head3 user

=head3 pass

=head3 cfpath

=head3 verbose

=head3 debug

=head3 main_file

=head3 default_file

=head3 menubar_file

=head3 app_menubar_file

=head3 toolbar_file

=head3 xresource

=head3 main

=head3 connection_file

=head3 connection

=head3 log_file_path

=head3 log_file_name

=head2 INSTANCE METHODS

=cut
