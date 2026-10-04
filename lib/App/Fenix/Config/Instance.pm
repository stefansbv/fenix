package App::Fenix::Config::Instance;

# ABSTRACT: Application instance configuration

use feature 'say';
use Moo;
use MooX::HandlesVia;
use Try::Tiny;
use App::Fenix::Types qw(
    Path
    Maybe
    Str
);

use Data::Dump;

with qw/App::Fenix::Role::FileUtils
        App::Fenix::Role::Utils/;

has 'instance_file' => (
    is  => 'ro',
    isa => Maybe[Path],
);

has '_instance' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    builder     => '_build_instance',
    handles     => {
        get_config  => 'get',
    },
);

has '_screen_names' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    init_arg    => undef,
    handles     => {
        get_screen => 'get',
    },
    default => sub {
        my $self = shift;
        return $self->get_config('geometry');
    },
);

sub _build_instance {
    my $self          = shift;
    my $instance_file = $self->instance_file;
    if ( $instance_file->is_file ) {
        $instance_file = $instance_file->stringify;
        say "# loading instance file\n    '$instance_file'";
        my $yaml = $self->load_yaml($instance_file);
        return $yaml;
    }
    else {
       say "No instance file found.";
    }
    return { geometry => '' };
}

sub save {
    my ( $self, $key, $value ) = @_;
    my $data = {};
    try { $data = $self->load_yaml( $self->instance_file ) }
    finally {
        $data->{geometry}{$key} = $value;
        $self->write_yaml( $self->instance_file, $data );
    };
    return;
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
