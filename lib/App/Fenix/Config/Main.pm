package App::Fenix::Config::Main;

# ABSTRACT: Main (generic) configurations

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    Path
);

with qw/App::Fenix::Role::FileUtils
        App::Fenix::Role::Utils/;

has 'main_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
);

has '_main' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_main',
    handles     => {
        get_main => 'get',
        all_main => 'keys',
    },
);

sub _build_main {
    my $self = shift;
    my $main_file = $self->main_file->stringify;
    my $yaml  = $self->load_yaml($main_file);
    return $yaml;
}

sub get_apps_exe_path {
    my ( $self, $name ) = @_;
    die "get_apps_exe_path: requires a 'name' parameter!" unless $name;
    if ( my $conf = $self->get_main('externalapps') ) {
        if ( exists $conf->{$name}{exe_path} ) {
            return $conf->{$name}{exe_path};
        }
        die "The externalapps '$name' configuration was not found!";
    }
    else {
        die "No 'externalapps' configuration found!";
    }
}

sub get_resource_path {
    my ( $self, $name ) = @_;
    die "get_resource_path: requires a 'name' parameter!" unless $name;
    if ( my $conf = $self->get_main('resource') ) {
        if ( exists $conf->{$name} ) {
            return $conf->{$name};
        }
        die "The resource '$name' configuration was not found!";
    }
    else {
        die "No 'resource' configuration found!";
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

=head3 main_file

=head3 _main

=head2 INSTANCE METHODS

=head3 _build_main

=head3 get_apps_exe_path

=head3 get_resource_path

=cut
