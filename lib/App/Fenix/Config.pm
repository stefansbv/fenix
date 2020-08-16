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
);
use Path::Tiny;
use Try::Tiny;
use File::HomeDir;
use File::ShareDir qw(dist_dir);
use Locale::TextDomain 1.20 qw(App-Fenix);
use App::Fenix::X qw(hurl);
use App::Fenix::Config::Connection;
use App::Fenix::Config::Main;

#-- required

has 'mnemonic' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

has 'user' => (
    is       => 'ro',
    isa      => Maybe[Str],
);

has 'pass' => (
    is       => 'ro',
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

#---

has 'sharedir' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $dir;
        return path $self->cfpath if $self->cfpath;
        try {
            $dir = dist_dir('Fapp-Fenix');
        }
        catch {
            $dir = 'share';
        };
        return path $dir;
    },
);

#-- hardcoded

# main config file
# has 'cfgmain' => (
#     is      => 'ro',
#     isa     => Str,
#     default => sub { 'etc/main.yml' },
# );

# and app default config file
# has 'cfgdefa' => (
#     is      => 'ro',
#     isa     => Str,
#     default => sub { 'etc/default.yml' },
# );

has 'etc_path' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->sharedir, 'etc';
    },
);

has 'main_file' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        my $self = shift;
        return path $self->etc_path, 'main.yml';
    },
);

has 'menubar_file' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        my $self = shift;
        return path $self->etc_path, 'menubar.yml';
    },
);

has 'toolbar_file' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        my $self = shift;
        return path $self->etc_path, 'toolbar.yml';
    },
);

has 'xresource' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->etc_path, 'xresource.xrdb';
    },
);

has 'main' => (
    is      => 'ro',
    isa     => FenixConfigMain,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Config::Main->new( main_file => $self->main_file, );
    },
    handles => [ 'get_apps_exe_path', 'get_resource_path', ],
);

has 'connection_file' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->sharedir, 'apps', $self->mnemonic,
            'etc/connection.yml';
    },
);

has 'connection_config' => (
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

has 'log_file_path' => (
    is       => 'ro',
    isa      => Path,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        return path( $ENV{FENIX_LOG_CONFIG} ) if $ENV{FENIX_LOG_CONFIG};
        return path( $self->etc_path, 'log.conf' );
    },
);

has 'log_file_name' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path( File::HomeDir->my_data, 'fenix.log' )->stringify;
    },
);

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 attr1

=head2 INSTANCE METHODS

=head3 meth1

=cut
