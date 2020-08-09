package App::Fenix::Model::Table::Record;

# ABSTRACT: Database table meta data record ( name => value )

use Moo;
use App::Fenix::Types qw(
    Int
    Str
    Maybe
);

has 'name'  => ( is  => 'ro', isa => Str );
has 'value' => ( is  => 'rw', isa => Maybe[Str] );

sub get_href {
    my $self = shift;
    return { $self->name => $self->value };
}

__PACKAGE__->meta->make_immutable;

=head1 SYNOPSIS

    my $rec = Fenix::Model::Table::Record->new( name => 'key1', value => 100 );

=head2 get_href

Return a hash reference: { name => value }.

=cut
