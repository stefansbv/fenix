package App::Fenix::Ctrl;

# ABSTRACT: Control

use Moo;
use App::Fenix::Types qw(
    Object
    ScalarRef
    Str
);
use namespace::autoclean;

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'type' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'ctrl' => (
    is       => 'ro',
    isa      => Object,
    required => 1,
);

1;
