package App::Fenix::Codings;

# ABSTRACT: Codes and values for list widgets

use Moo;
use Sub::HandlesVia;
use App::Fenix::Types qw(
    ArrayRef
    FenixModelDB
    Str
);

has '_code' => (
    is          => 'ro',
    handles_via => ['Hash'],
    lazy        => 1,
    default     => sub { {} },
    handles     => {
        get_code  => 'get',
        set_code  => 'set',
        all_codes => 'keys',
    },
);

has 'model_db' => (
    is       => 'ro',
    #isa      => FenixModelDB,
    lazy     => 1,
    required => 1,
);

# has 'dict_data' => (
#     is       => 'ro',
#     isa      => ArrayRef,
#     lazy     => 1,
#     required => 1,
# );

sub get_coding_init {
    my ( $self, $field, $para, $widget ) = @_;

    my $label_label
        # widget type       key name
        = $widget eq 'l' ? 'label'
        : $widget eq 'm' ? '-name'
        :                  '-name'
        ;

    my $value_label
        # widget type       key name
        = $widget eq 'l' ? 'value'
        : $widget eq 'm' ? '-value'
        :                  '-value'
        ;

    if ( !$self->get_code($field) ) {

        # Query database table
        $self->set_code($field, $self->model_db
            ->tbl_dict_query( $para, $label_label, $value_label ));
        # $self->set_code($field, $self->dict_data);
    }

    # if (   $para->{default} =~ m{null}i
    #     or $para->{default} eq q{} )    # compatible with old configs
    # {

    #     # Add and empty option
    #     unshift @{ $self->{_code}{$field} },
    #         {
    #         $label_label => ' ',
    #         $value_label => ' ',
    #         };
    # }

    return $self->get_code($field);
}

1;

=head1 SYNOPSIS

   use App::Fenix::Codings;

   my $codes = App::Fenix::Codings->new();

=head2 get_coding_init

Return the data structure used to fill the list of choices (options)
of Tk::JComboBox widgets.

Initialize the datastructure from the database when needed.  The
procedure is: check key, if exists return a hash ref else query the
database.

Add the default value defined in configuration, if not exists in table.

Different labels for different widgets:

 -name and -value for JCombobox
 label and  value for MatchingBE

Data example:

  {   statuscode => [
          { -name => "Cancelled",  -value => "C" },
          { -name => "Disputed",   -value => "D" },
          { -name => "In Process", -value => "P" },
          { -name => "On Hold",    -value => "H" },
          { -name => "Resolved",   -value => "R" },
          { -name => "Shipped",    -value => "S" },
      ],
  }

=head2 get_coding

Return codes.

=cut
