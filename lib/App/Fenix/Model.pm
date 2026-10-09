package App::Fenix::Model;

# ABSTRACT: The Model

use feature 'say';
use Moo;
use Sub::HandlesVia;
use Try::Tiny;
#use Path::Tiny;
use App::Fenix::Types qw(
    Bool
    FenixConfig
    FenixModelDB
    FenixModelTable
    Maybe
    Path
    Str
);
use App::Fenix::X qw(hurl);
use App::Fenix::Model::DB;
use App::Fenix::Model::Table;
use namespace::clean;

has 'config' => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'verbose' => (
    is      => 'ro',
    isa     => Bool,
    default => sub {
        my $self = shift;
        return $self->config->verbose;
    },
);

has 'debug' => (
    is      => 'ro',
    isa     => Bool,
    default => sub {
        my $self = shift;
        return $self->config->debug;
    },
);

has 'db' => (
    is      => 'ro',
    isa     => FenixModelDB,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Model::DB->new( config => $self->config, );
    },
);

has '_table' => (
    is       => 'ro',
    handles_via   => ['Hash'],
    isa      => Maybe[FenixModelTable],
    lazy     => 1,
    init_arg => undef,
    clearer  => 'reset_table',
    default  => sub { {} },
        handles     => {
        get_table  => 'get',
        add_table  => 'set',
        all_tables => 'keys',
        rm_table   => 'delete',
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
