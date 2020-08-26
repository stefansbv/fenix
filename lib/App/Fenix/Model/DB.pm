package App::Fenix::Model::DB;

# ABSTRACT: The DB Model

use feature 'say';
use Moo;
# use Data::Compare;
# use List::Compare;
# use Regexp::Common;
use Try::Tiny;
use App::Fenix::Types qw(
    Bool
    DBIdb
    DBIxConnector
    FenixConfig
    FenixEngine
    FenixTarget
);
# use App::Fenix::Exceptions;
use App::Fenix::Config;
#use App::Fenix::Codings;
#use App::Fenix::Observable;
use App::Fenix::Target;
#use App::Fenix::Utils;
#use App::Fenix::Model::Update;
#use App::Fenix::Model::Update::Compare;
use namespace::autoclean;

#use Data::Dump qw/dump/;

has 'config' => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'debug' => (
    is  => 'ro',
    isa => Bool,
);

has 'verbose' => (
    is  => 'ro',
    isa => Bool,
);

has 'target' => (
    is      => 'ro',
    isa     => FenixTarget,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $conf = $self->config->connection;
        return App::Fenix::Target->new(
            uri => $conf->uri,
        );
    },
);

has 'engine' => (
    is      => 'ro',
    isa     => FenixEngine,
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->target->engine;
    },
);

has 'dbh' => (
    is      => 'ro',
    isa     => DBIdb,
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->engine->dbh;
    },
);


1;
