package App::Fenix::Model::DB;

# ABSTRACT: The DB Model

use feature 'say';
use Moo;
use Try::Tiny;
use SQL::Abstract::More;
use App::Fenix::Types qw(
    Bool
    DBIdb
    DBIxConnector
    FenixConfig
    FenixEngine
    FenixTarget
);
use App::Fenix::Exceptions;
use App::Fenix::Config;
use App::Fenix::Target;
use namespace::autoclean;

use Data::Dump qw/dump/;

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

=head2 build_sql_where

Return a hash reference suitable for L<SQL::Abstract>, containing
where clause attributes.

Table columns (fields) used in the screen have a configuration named
I<findtype> that is used to build the appropriate where clause.

Valid configuration options are:

=over

=item contains - the field value contains the search string

=item full   - the field value equals the search string

=item date     - special case for date type fields

=item none     - no search for this field

=back

Second parameter 'option' is passed to quote4like.

If the search string equals with I<%> or I<!>, then generated where
clause will be I<field1> IS NOT NULL and respectively I<field2> IS
NULL.

=cut

sub build_sql_where {
    my ( $self, $opts ) = @_;

    my $where = {};
    foreach my $field ( keys %{ $opts->{where} } ) {
        my $attrib    = $opts->{where}{$field};
        my $searchstr = $attrib->[0];
        my $find_type = $attrib->[1];
        unless ($find_type) {
            die "Undefined 'find_type' for '$field'";
        }

        if ( $find_type eq 'contains' ) {
            my $cmp = $self->cmp_function($searchstr);
            if ($cmp eq '-CONTAINING') {

                # Firebird specific
                $where->{$field} = { $cmp => $searchstr };
            }
            else {
                $where->{$field} = {
                    $cmp => $self->quote4like(
                        $searchstr, $opts->{options}
                    )
                };
            }
        }
        elsif ( $find_type eq 'full' ) {
            $where->{$field} = $searchstr;
        }
        elsif ( $find_type eq 'date' ) {
            my $ret = $self->process_date_string($searchstr);
            if ( $ret eq 'dataerr' ) {
                # $self->_print('warn#Wrong search parameter');
                say 'warn#Wrong search parameter';
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

    my $driver = $self->config->connection->driver; # make this a parameter?

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

sub query_record {
    my ( $self, $opts ) = @_;

    my $table = $opts->{table};
    my $cols  = $opts->{columns};
    my $where = $opts->{where};

    my $sql = SQL::Abstract->new( special_ops => $self->special_ops );

    my ( $stmt, @bind ) = $sql->select( $table, $cols, $where );
    $self->debug_print_sql('query_record', $stmt, \@bind) if $self->debug;

    my $hash_ref;
    try {
        $hash_ref = $self->dbh->selectrow_hashref( $stmt, undef, @bind );
    }
    catch {
        $self->db_exception($_, 'Query failed');
    };

    return $hash_ref;
}

sub debug_print_sql {
    my ( $self, $meth, $stmt, $bind ) = @_;
    warn "debug_print_sql: wrong params!"
        unless $meth and $stmt and ref $bind;
    my $bind_params_no = scalar @{$bind};
    my $params = 'none';
    if ( $bind_params_no > 0 ) {
        my @para = map { defined $_ ? $_ : 'undef' } @{$bind};
        $params  = scalar @para > 0 ? join( ', ', @para ) : 'none';
    }
    say "---";
    say "$meth:";
    say "  SQL=$stmt";
    say "  Params=($params)";
    say "---";
    return;
}

sub db_exception {
    my ( $self, $exc, $context ) = @_;

    say "Exception: '$exc'";
    say "Context  : '$context'";

    if ( my $e = Exception::Base->catch($exc) ) {
        say "Catched!";

        if ( $e->isa('Exception::Db::Connect') ) {
            my $logmsg  = $e->logmsg;
            my $usermsg = $e->usermsg;
            say "ExceptionConnect: $usermsg :: $logmsg";
            $e->throw;    # rethrow the exception
        }
        elsif ( $e->isa('Exception::Db::SQL') ) {
            my $logmsg  = $e->logmsg;
            my $usermsg = $e->usermsg;
            say "ExceptionSQL: $usermsg :: $logmsg";
            $e->throw;    # rethrow the exception
        }
        else {

            # Throw other exception
            say "ExceptioOther new";
            my $message = $self->user_message($exc);
            say "Message:   '$message'";
            Exception::Db::SQL->throw(
                logmsg  => $message,
                usermsg => $context,
            );
        }
    }
    else {
        say "New thrown (model)";
        Exception::Db::SQL->throw(
            logmsg  => "error#$exc",
            usermsg => $context,
        );
    }

    return;
}

# params:
# {
# pkcol => "ordernumber",
# table => "v_orders",
# where => { customername => ["%", "notnull"], statuscode => ["C", "full"] },
# }

1;
