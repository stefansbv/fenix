package ConfigPaths;

use Moo;
use App::Fenix::Types qw(
    Maybe
    Str
);

with 'App::Fenix::Role::Paths';

has 'cfpath' => (
    is       => 'ro',
    isa      => Maybe[Str],
);

has 'mnemonic' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
);

1;
