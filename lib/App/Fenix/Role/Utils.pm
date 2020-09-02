package App::Fenix::Role::Utils;

# ABSTRACT: Role for utils

use 5.0100;
use utf8;
use Try::Tiny;
use App::Fenix::X qw(hurl);
use Moo::Role;

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

sub trim {
    my ( $self, @text ) = @_;
    for (@text) {
        s/^\s+//;
        s/\s+$//;
    }
    return wantarray ? @text : "@text";
}

# Was parse_message
sub categorize_message {
    my ($self, $text) = @_;
    (my $type, $text) = split /#/, $text, 2;

    # Allow empty type
    unless ($text) {
        $text = $type;
        $type = q{};
    }
    my $color;
  SWITCH: {
        $type eq 'error' && do { $color = 'darkred';   last SWITCH; };
        $type eq 'info'  && do { $color = 'darkgreen'; last SWITCH; };
        $type eq 'warn'  && do { $color = 'orange';    last SWITCH; };
        $color = 'black';                    # default
    }
    # return ($text, $color, $type);
    return ($text, $color);
}

no Moo::Role;

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head2 INSTANCE METHODS

=head2 sort_hash_by_id

Use ST to sort hash by value (Id), returns an array or an array
reference of the sorted items.

=cut
