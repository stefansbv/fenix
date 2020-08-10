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
);
use Path::Tiny;
use Try::Tiny;
use File::HomeDir;
use File::ShareDir qw(dist_dir);
use Locale::TextDomain 1.20 qw(App-Fenix);
use App::Fenix::X qw(hurl);

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
            $dir = dist_dir('Fenix');
        }
        catch {
            $dir = 'share';
        };
        return path $dir;
    },
);

#-- hardcoded

# main config file
has 'cfgmain' => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'etc/main.yml' },
);

# and app default config file
has 'cfgdefa' => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'etc/default.yml' },
);

has 'menubar_file' => (
    is      => 'ro',
    isa     => Path,
    default => sub {
        my $self = shift;
        return path $self->sharedir, 'etc/menubar.yml';
    },
);

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
