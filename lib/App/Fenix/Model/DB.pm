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
#use App::Fenix::Model::Update;
#use App::Fenix::Model::Update::Compare;
use namespace::autoclean;

#use Data::Dump qw/dump/;

with 'App::Fenix::Role::DBUtils';

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

#---

sub build_sql_where {
    my ( $self, $opts ) = @_;

    my $where = {};

    foreach my $field ( keys %{ $opts->{where} } ) {
        my $attrib    = $opts->{where}{$field};
        my $searchstr = $attrib->[0];
        my $find_type = $attrib->[1];

        unless ($find_type) {
            die "Unknown 'find_type': $find_type for '$field'";
        }

        if ( $find_type eq 'contains' ) {
            my $cmp = $self->cmp_function($searchstr);
            if ($cmp eq '-CONTAINING') {
                # Firebird specific
                $where->{$field} = { $cmp => $searchstr };
            }
            else {
                $where->{$field} = {
                    $cmp => Tpda3::Utils->quote4like(
                        $searchstr, $opts->{options}
                    )
                };
            }
        }
        elsif ( $find_type eq 'full' ) {
            $where->{$field} = $searchstr;
        }
        elsif ( $find_type eq 'date' ) {
            my $ret = Tpda3::Utils->process_date_string($searchstr);
            if ( $ret eq 'dataerr' ) {
                $self->_print('warn#Wrong search parameter');
                return;
            }
            else {
                $where->{$field} = $ret;
            }
        }
        elsif ( $find_type eq 'isnull' ) {
            $where->{$field} = undef;
        }
        elsif ( $find_type eq 'notnull' ) {
            $where->{$field} = undef;
            my $notnull = q{IS NOT NULL};
            $where->{$field} = \$notnull;
        }
        elsif ( $find_type eq 'none' ) {

            # just skip
        }
        else {
            die "Unknown 'find_type': $find_type for '$field'";
        }
    }

    return $where;
}

sub cmp_function {
    my ( $self, $search_str ) = @_;

    die "cmp_function: missing required arguments: '\$search_str'\n"
        unless defined $search_str;

    my $ignore_case = 1;
    if ( $search_str =~ m/\p{IsLu}{1,}/ ) {
        $ignore_case = 0;
    }

    my $driver = $self->config->connection->driver;

    my $cmp;
  SWITCH: for ($driver) {
        /^$/ && warn "EE: empty database driver name!\n";
        /cubrid/xi && do {
            $cmp = $ignore_case ? '-LIKE' : '-LIKE';
            last SWITCH;
        };
        /fb|firebird/xi && do {
            $cmp = $ignore_case ? '-CONTAINING' : '-LIKE';
            last SWITCH;
        };
        /pg|postgresql/xi && do {
            $cmp = $ignore_case ? '-ILIKE' : '-LIKE';
            last SWITCH;
        };
        /sqlite/xi && do {
            $cmp = $ignore_case ? '-LIKE' : '-LIKE';
            last SWITCH;
        };

        # Default
        warn "WW: Unknown database driver name: $driver!\n";
        $cmp = '-LIKE';
    }

    return $cmp;
}

# params:
# {
# pkcol => "ordernumber",
# table => "v_orders",
# where => { customername => ["%", "notnull"], statuscode => ["C", "full"] },
# }

1;
