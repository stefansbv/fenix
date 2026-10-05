package App::Fenix::Ctrl;

# ABSTRACT: Control

use Moo;
use App::Fenix::Types qw(
    Object
    Maybe
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

has 'variable' => (
    is       => 'ro',
    isa      => Maybe[Object|ScalarRef|Str],
    required => 0,
);

has 'ctrl' => (
    is       => 'ro',
    isa      => Object,
    required => 1,
);

1;
