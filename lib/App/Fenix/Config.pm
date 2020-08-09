package App::Fenix::Config;

# ABSTRACT: A TkConfig Extension

use 5.010;
use utf8;
use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    Bool
    Path
);
use Path::Tiny;
use File::ShareDir qw(dist_dir);
use Try::Tiny;
use File::HomeDir;
use Locale::TextDomain 1.20 qw(App-Fenix);
use App::Fenix::X qw(hurl);

extends 'Config::GitLike';

has '+confname' => ( default => 'fenix.conf' );
has '+encoding' => ( default => 'UTF-8' );

has 'sharedir' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $path;
        try {
            $path = dist_dir('App-Fenix');
        }
        catch {
            $path = 'share';
        };
        return path $path;
    },
);

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

my $SYSTEM_DIR = undef;                      # works ok for Linux ;)

sub user_dir {
    my $hd = File::HomeDir->my_home or hurl config => __(
        "Could not determine home directory"
    );
    return path $hd, '.fenix';
}

sub system_dir {
    path $SYSTEM_DIR || do {
        require Config;
        $Config::Config{prefix}, 'etc', 'fenix';
    };
}

sub system_file {
    my $self = shift;
    return path $ENV{Fenix_SYS_CONFIG}
        || $self->system_dir->path( $self->confname );
}

sub global_file { shift->system_file }

sub user_file {
    my $self = shift;
    return path $ENV{Fenix_USR_CONFIG}
        || path $self->user_dir, $self->confname;
}

sub local_file {
    return path $ENV{Fenix_CONFIG} if $ENV{Fenix_CONFIG};
    return path shift->confname;
}

sub dir_file { shift->local_file }

sub get_section {
    my ( $self, %p ) = @_;
    $self->load unless $self->is_loaded;
    my $section = lc $p{section} // '';
    my $data    = $self->data;
    return {
        map  {
            ( split /[.]/ => $self->initial_key("$section.$_") )[-1],
            $data->{"$section.$_"}
        }
        grep { s{^\Q$section.\E([^.]+)$}{$1} } keys %{$data}
    };
}

# Mock up original_key for older versions of Config::GitLike.
eval 'sub original_key { $_[1] }' unless __PACKAGE__->can('original_key');

sub initial_key {
    my $key = shift->original_key(shift);
    return ref $key ? $key->[0] : $key;
}

has 'xresource' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return path $self->sharedir, 'etc', 'xresource.xrdb';
    },
);

1;
