package App::Fenix::Role::Utils;

# ABSTRACT: Role for utils

use 5.0100;
use utf8;
use Try::Tiny;
use Encode qw(is_utf8 decode);
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
    die "categorize_message: missing required parameter \$text"
        unless $text;
    ( my $type, $text ) = split /#/, $text, 2;

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

sub decode_unless_utf {
    my ($self, $value) = @_;
    $value = decode( 'utf8', $value ) unless is_utf8($value);
    return $value;
}

sub dateentry_parse_date {
    my ( $self, $format, $date ) = @_;
    return unless $date;

    # Default date style format
    $format = 'iso' unless $format;

    my ( $y, $m, $d );
  SWITCH: for ($format) {
        /^$/ && die "dateentry_parse_date: the \$format parameter is required'\n";
        /german/i && do {
            ( $d, $m, $y )
                = ( $date =~ m{([0-9]{2})\.([0-9]{2})\.([0-9]{4})} );
            last SWITCH;
        };
        /iso/i && do {
            ( $y, $m, $d )
                = ( $date =~ m{([0-9]{4})\-([0-9]{2})\-([0-9]{2})} );
            last SWITCH;
        };
        /usa/i && do {
            ( $m, $d, $y )
                = ( $date =~ m{([0-9]{2})\/([0-9]{2})\/([0-9]{4})} );
            last SWITCH;
        };

        # DEFAULT
        die "dateentry_parse_date: unknown date format: $format\n";
    }
    return ( $y, $m, $d );
}

sub dateentry_format_date {
    my ( $self, $format, $y, $m, $d ) = @_;
    die "dateentry_format_date: the \$y, \$m and \$d parameters are required\n"
        unless defined $y and defined $m and defined $d;

    # Default date style format
    $format = 'iso' unless $format;

    my $date;
  SWITCH: for ($format) {
        /^$/ && die "dateentry_format_date: the \$format parameter is required\n";
        /german|dmy/i && do {
            $date = sprintf( "%02d.%02d.%4d", $d, $m, $y );
            last SWITCH;
        };
        /iso/i && do {
            $date = sprintf( "%4d-%02d-%02d", $y, $m, $d );
            last SWITCH;
        };
        /usa/i && do {
            $date = sprintf( "%02d/%02d/%4d", $m, $d, $y );
            last SWITCH;
        };

        # DEFAULT
        die "dateentry_format_date: unknown date format: $format\n";
    }
    return $date;
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

=head2 decode_unless_utf

Decode a string if is not utf8.

=cut
