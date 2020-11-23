package App::Fenix::Config::Application;

# ABSTRACT: Application configurations

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    Path
);

with qw/App::Fenix::Role::FileUtils
        App::Fenix::Role::Utils/;

has 'application_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
);

has '_application' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_application',
    handles     => {
        get_application => 'get',
    },
);

sub _build_application {
    my $self = shift;
    my $application_file = $self->application_file->stringify;
    my $yaml  = $self->load_yaml($application_file);
    return $yaml->{application};
}

sub get_application_limits {
    my ( $self, $name ) = @_;
    die "get_application_limits: requires a 'name' parameter!" unless $name;
    if ( my $conf = $self->get_application('limits') ) {
        if ( exists $conf->{$name}{search} ) {
            return $conf->{$name}{search};
        }
        die "The application '$name' configuration was not found!";
    }
    else {
        die "No 'application' configuration found!";
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

=head3 application_file

=head3 _application

=head2 INSTANCE METHODS

=head3 _build_application

=cut
