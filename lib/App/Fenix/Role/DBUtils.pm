package App::Fenix::Role::DBUtils;

# ABSTRACT: Various utility functions

use feature 'say';
use utf8;
use Moo::Role;
use MooX::HandlesVia;
use Encode qw(is_utf8 decode);
use Try::Tiny;
use Path::Tiny;
use DateTime;
use DateTime::Locale;

has '_transformations' => (
    is          => 'ro',
    handles_via => 'Hash',
    init_arg    => undef,
    default     => sub {
        return {
            datey   => 'year_month',
            dateym  => 'year_month',
            datemy  => 'year_month',
            dateiso => 'date_string',
            dateamb => 'date_string',
            nothing => 'do_error',
            error   => 'do_error',
        };
    },
    handles => { get_transformations => 'get', },
);

sub dateentry_parse_date {
    my ( $self, $date, $format ) = @_;
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
    my ( $self, $y, $m, $d, $format ) = @_;
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

sub quote4like {
    my ( $self, $text, $option ) = @_;

    if ( $text =~ m{%}xm ) {
        return $text;
    }
    else {
        $option ||= q{C};    # default 'C'
        return qq{$text%} if $option eq 'S';    # (S)tart with
        return qq{%$text} if $option eq 'E';    # (E)nd with
        return qq{%$text%};                     # (C)ontains
    }
}

sub special_ops {
    my $self = shift;
    return [
        {   regex   => qr/^extractyear$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('extract (year from')
                    . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },
        {   regex   => qr/^extractmonth$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = $self->_sqlcase('extract (month from')
                    . " $label) = $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },
        # special op for PostgreSQL syntax: field SIMILAR TO 'regex1'
        {   regex   => qr/^similar_to$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = "$label "
                    . $self->_sqlcase('similar to ')
                    . " $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },
        # special op for PostgreSQL syntax: field ~ 'regex1'
        {   regex   => qr/^match$/i,
            handler => sub {
                my ( $self, $field, $op, $arg ) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $sql           = "$label "
                    . $self->_sqlcase('~ ')
                    . " $placeholder ";
                my @bind = $self->_bindtype( $field, @$arg );
                return ( $sql, @bind );
            }
        },
    ];
}

sub process_date_string {
    my ( $self, $search_input ) = @_;
    my $dtype = $self->identify_date_string($search_input);
    my $where = $self->format_query($dtype);
    return $where;
}

sub identify_date_string {
    my ( $self, $str ) = @_;
    my $si = qr![-]!;
    my $so = qr![/]|[.]!;
    my $sa = qr![/]|[.]|[-]!;

    #            When date format is...                     Type is ...
    return
          $str eq q{}                                ? 'nothing'
        : $str =~ m/^(\d{4})$si(\d{2})$si(\d{2})$/   ? "dateiso:$str"
        : $str =~ m/^(\d{2})$so(\d{2})$so(\d{4})$/   ? "dateamb:$str"
        : $str =~ m/^(\d{4})$sa(\d{1,2})$/           ? "dateym:$1:$2"
        : $str =~ m/^(\d{1,2})$sa(\d{4})$/           ? "datemy:$2:$1"
        : $str =~ m/^(\d{4})$/                       ? "datey:$1"
        :                                              "error:$str";
}

sub format_query {
    my ( $self, $type ) = @_;
    die "format_query: the 'type' parameter is required"
        unless $type;
    my ( $directive, $year, $month ) = split /:/, $type, 3;
    my $where;
    if ( my $meth = $self->get_transformations($directive) ) {
        $where = $self->$meth( $year, $month );
    }
    else {

        # warn "Unrecognized directive '$directive'";
        $where = $directive;
    }
    return $where;
}

sub year_month {
    my ( $self, $year, $month ) = @_;
    my $where = {};
    $where->{-extractyear}  = [$year]  if ($year);
    $where->{-extractmonth} = [$month] if ($month);
    return $where;
}

sub date_string {
    my ($self, $date) = @_;
    return $date;
}

sub do_error {
    my ($self, $date) = @_;
    die "String not identified or empty!\n";
    return;
}

sub ins_underline_mark {
    my ( $self, $label, $position ) = @_;
    die "ins_underline_mark: the \$label and \$position parameters are required'"
        unless $label and defined $position;
    substr( $label, $position, 0, '&' );
    return $label;
}

sub deaccent {
    my ( $self, $text ) = @_;
    $text =~ tr/ăĂãÃâÂîÎșȘşŞțȚţŢ/aAaAaAiIsSsStTtT/;
    return $text;
}

sub decode_unless_utf {
    my ($self, $value) = @_;
    $value = decode( 'utf8', $value ) unless is_utf8($value);
    return $value;
}

sub dt_today {
    my ( $self, $locale ) = @_;
    $locale //= 'ro';    # the default locale is ro ;)
    return DateTime->now( locale => $locale );
}

sub month_names {
    my ( $self, $format, $locale ) = @_;
    my $today = $self->dt_today($locale);
    my $arr_ref =
        $format eq 'abbrev' ? $today->locale->month_stand_alone_abbreviated
      : $format eq 'narrow' ? $today->locale->month_stand_alone_narrow
      : $format eq 'wide'   ? $today->locale->month_stand_alone_wide
      :                    undef;
    die "month_names: '$format' is not a valid format, try: abbrev, narrow or wide\n"
        unless $arr_ref;
    return $arr_ref;
}

sub day_names {
    my ( $self, $format, $locale ) = @_;
    my $today = $self->dt_today($locale);
    my $arr_ref =
        $format eq 'abbrev' ? $today->locale->day_stand_alone_abbreviated
      : $format eq 'narrow' ? $today->locale->day_stand_alone_narrow
      : $format eq 'wide'   ? $today->locale->day_stand_alone_wide
      :                    undef;
    die "'$format' is not a valid format, try: abbrev, narrow or wide\n"
      unless $arr_ref;
    return $arr_ref;
}

sub get_month_name {
    my ( $self, $month, $format, $locale ) = @_;
    die "get_month_name: missing month parameter"
        unless defined $month;
    die "get_month_name: expecting a number for month parameter"
        unless $month =~ m/\d{1,2}/gmi;
    die "get_month_name: wrong month parameter: $month"
        if $month <= 0 or $month > 12;
    my $months = $self->month_names( $format, $locale );
    my $i      = $month - 1;
    return $months->[$i];
}

sub get_day_name {
    my ( $self, $day, $format, $locale ) = @_;
    die "get_day_name: missing day parameter"
        unless defined $day;
    die "get_day_name: expecting a number for day parameter"
        unless $day =~ m/\d/gmi;
    die "get_day_name: wrong day parameter: $day"
      if $day <= 0 or $day > 7;
    my $days = $self->day_names( $format, $locale );
    my $i    = $day - 1;
    return $days->[$i];
}

no Moo::Role;

1;

__END__

=head1 SYNOPSIS

Various utility functions used by all other modules.

=head2 transformations

Global hash reference.

=head2 trim

Trim strings or arrays.

=head2 dateentry_parse_date

Parse date for Tk::DateEntry.

=head2 dateentry_format_date

Format date for Tk::DateEntry.

=head2 sort_hash_by_id

Use ST to sort hash by value (Id), returns an array or an array
reference of the sorted items.

=head2 filter_hash_by_keyvalue

Use ST to sort hash by value (Id), returns an array ref of the sorted
items, filtered by key => value.

=head2 quote4like

Surround text with '%', by default, for SQL LIKE.  An optional second
parameter can be used for 'start with' or 'end with' sintax.

If option parameter is not 'C', 'S', or 'E', 'C' is assumed.

=head2 special_ops

SQL::Abstract special ops for EXTRACT (YEAR|MONTH FROM field) = word1.

Note: Not compatible with SQLite.

=head2 process_date_string

Try to identify the input string as full date, year or month and year
and return a where clause.

=head2 identify_date_string

Identify format of the I<input> I<string> from a date type field and
return the matched pieces in a string as separate values where the
separator is the colon character.

=head2 format_query

Execute the appropriate sub and return the where attributes Choices
are defined in the I<$transformations> hash.

=head2 year_month

Case of string identified as year and/or month.

=head2 date_string

Case of string identified as full date string, regardless of the format.

=head2 do_error

Case of string not identified or empty.

=head2 ins_underline_mark

Insert ampersand character for underline mark in menu.

=head2 deaccent

Remove Romanian accented characters.

TODO: Add other accented characters, especially for German and Hungarian.

=head2 decode_unless_utf

Decode a string if is not utf8.

=head2 parse_message

Parse a message text in the following format:

   error#Message text
   info#Message text
   warn#Message text

and return the coresponding mesage text and color.

=head2 dt_today

Returns a DateTime object instance for the 'ro' locale, the default or
the locale name provided with the parameter;

=head2 month_names

Returns an ordered array reference with the month names from a locale.
January is at index 0.

The parameters are:

format: (abbrev, narrow or wide), required

locale: all names suported by L<DateTime::Locale> module, the default
        is 'ro'

=head3 day_names

=head3 get_month_name

=head3 get_day_name

=cut
