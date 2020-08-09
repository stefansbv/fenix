package App::Fenix::Cal;

# ABSTRACT: Calendar year and month

use Moo;
use Time::Moment;
use App::Fenix::Types qw(
    Str
);

has 'year' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => sub {
        my $tm     = Time::Moment->now;
        my $tm_new = $tm->minus_months(1);
        return $tm_new->year;
    },
);

has 'month' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    default  => sub {
        my $tm     = Time::Moment->now;
        my $tm_new = $tm->minus_months(1);
        my $month = $tm_new->month;
        return sprintf("%02s", $month);
    },
);

__PACKAGE__->meta->make_immutable;

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
