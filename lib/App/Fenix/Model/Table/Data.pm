package App::Fenix::Model::Table::Data;

# ABSTRACT: Database table data

use Moo;
use Sub::HandlesVia;
use App::Fenix::Types qw(
    ArrayRef
    Maybe
    Str
    FenixRecord
);
use App::Fenix::Model::Table::Record;
use namespace::clean;
use Data::Dump qw/dump/;

# has 'table' => (
#     is  => 'ro',
#     isa => Str,
# );

# has 'view' => (
#     is  => 'ro',
#     isa => Str,
# );


1;

=head1 SYNOPSIS

    my $table  = App::Fenix::Model::Table::Data->new(



    );

=cut
