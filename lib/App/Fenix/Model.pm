package App::Fenix::Model;

# ABSTRACT: The Model

use 5.010;
use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    FenixConfig
    FenixConfigUtils
    FenixCal
    Str
    Path
);
use App::Fenix::X qw(hurl);
use App::Fenix::Cal;
use Try::Tiny;
use Path::Tiny;

has 'config' => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'utils' => (
    is       => 'ro',
    isa      => FenixConfigUtils,
    required => 1,
);

has 'cal' => (
    is      => 'ro',
    isa     => FenixCal,
    lazy    => 1,
    default => sub {
        return App::Fenix::Cal->new;
    },
    handles => {
        month_i => 'month',
        year_i  => 'year',
    },
);

#--  anul si luna de lucru

has 'year_l' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->year_i;
    },
);

has 'month_l' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    coerce  => sub { length $_[0] == 1 ? sprintf("%02s", $_[0]) : $_[0] },
    default => sub {
        my $self = shift;
        return $self->month_i;
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
