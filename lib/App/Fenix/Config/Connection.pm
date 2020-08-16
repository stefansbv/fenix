package App::Fenix::Config::Connection;

# ABSTRACT: Database connection configuration

use Moo;
use Try::Tiny;
use URI::db;
use Locale::TextDomain qw(App-Fenix);
use App::Fenix::X qw(hurl);
use App::Fenix::Types qw(
    Path
    Maybe
    Str
    URIdb
);

with qw/App::Fenix::Role::FileUtils
        App::Fenix::Role::Utils/;

has 'connection_file' => (
    is  => 'ro',
    isa => Maybe[Path],
);

has 'uri' => (
    is       => 'rw',
    isa      => Str,
);

has 'uri_db' => (
    is      => 'ro',
    isa     => URIdb,
    lazy    => 1,
    default => sub {
        my $self = shift;
        if ( $self->uri ) {
            return $self->_build_uri_from_string;
        }
        else {
            if ( $self->connection_file ) {
                return $self->_build_uri_from_yaml;
            }
            else {
                die "A connection file or an URI is required.";
            }
        }
    },
);

has 'driver' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->engine;
    },
);

has 'host' => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->host;
    },
);

has 'dbname' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->dbname;
    },
);

has 'port' => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->port;
    },
);

has 'user' => (
    is      => 'ro',
    isa     => Maybe[Str],
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->uri_db->user;
    },
);

has 'role' => (
    is  => 'rw',
    isa => Maybe[Str],
);

sub _build_uri_from_string {
    my $self = shift;
    my $uri = URI::db->new( $self->uri );

    # Search for ib_role - code inspired from Sqitch ;)
    if ( my @p = $uri->query_params ) {
        while (@p) {
            my ( $k, $v ) = ( shift @p, shift @p );
            $self->role($v) if $k =~ m{ib_role};
        }
    }
    $self->uri( $uri->as_string );
    return $uri;
}

sub _build_uri_from_yaml {
    my $self = shift;
    my $data;
    try {
        $data = $self->load_yaml( $self->connection_file->stringify );
    }
    catch {
        hurl info_conn =>
            __x( "[EE] Failed to read the connection configuration file:\n    '{file}'",
                 file => $self->connection_file );
    };
    my $conn = $data->{connection};
    my $uri  = URI::db->new;
    $uri->engine( $conn->{driver} );
    $uri->dbname( $conn->{dbname} );
    $uri->host( $conn->{host} ) if $conn->{host};
    $uri->port( $conn->{port} ) if $conn->{port};
    $uri->user( $conn->{user} ) if $conn->{user};

    # Workaround to add a role param
    if ( my $role = $conn->{role} ) {
        my $str = $uri->as_string;
        $uri = URI::db->new("$str?ib_role=$role");
        $self->role($role);
    }
    $self->uri( $uri->as_string );
    return $uri;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 Synopsis


=head1 Description


=head1 Interface

=head2 Attributes

=head3 attr1

=head2 Instance Methods

=head3 meth1

=cut
