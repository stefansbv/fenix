package App::Fenix::Role::Element;

# ABSTRACT: The Element Role

use Moo::Role;
use App::Fenix::Types qw(
    TkFrame
    FenixView
    Str
);
use App::Fenix::Ctrl;
use namespace::autoclean;

has 'view' => (
    is       => 'ro',
    isa      => FenixView,
    required => 1,
    handles  => [qw( frame config model )],
);

has 'nb_frame' => (
    is       => 'ro',
    isa      => TkFrame,
    required => 0,
);

has 'bg_color' => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->frame->cget('-background');
    },
);


1;
