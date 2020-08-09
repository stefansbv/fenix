package App::Fenix::Role::Utils;

# ABSTRACT: Role for utils

use 5.0100;
use utf8;
use Try::Tiny;
use App::Fenix::X qw(hurl);
use Moose::Role;

sub sort_hash_by_id {
    my ( $self, $attribs ) = @_;
    foreach my $k ( keys %{$attribs} ) {
        if ( !exists $attribs->{$k}{id} ) {
            warn "sort_hash_by_id: '$k' does not have an 'id' attribute\n";
        }
    }

    #-- Sort by id
    #- Keep only key and id for sorting
    my %temp = map { $_ => $attribs->{$_}{id} } keys %{$attribs};

    #- Sort with  ST
    my @attribs = map { $_->[0] }
        sort { $a->[1] <=> $b->[1] }
        map { [ $_ => $temp{$_} ] }
        keys %temp;

    return wantarray ? @attribs : \@attribs;
}



no Moose::Role;

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 sub conf_new

=head2 INSTANCE METHODS

=head3 load_conf

=head3 load_yaml

=head3 conf_new

=cut
