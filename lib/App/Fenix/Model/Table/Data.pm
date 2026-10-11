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

has '_record' => (
    is          => 'ro',
    handles_via => ['Array'],
    init_arg    => 'record',
    required    => 1,
    lazy        => 1,
    default     => sub { [] },
    coerce      => sub {
        my $recs = shift;
        return [ map {
                App::Fenix::Model::Table::Record->new(
                    name  => $_,
                    value => undef
                )
            } @{$recs}
        ];
    },
    isa     => ArrayRef[FenixRecord],
    handles => {
        get_rec    => 'get',
        all_recs   => 'elements',
        map_recs   => 'map',
        find_rec   => 'first',
        count_recs => 'count',
    },
);

1;

=head1 SYNOPSIS

    my $table  = App::Fenix::Model::Table::Data->new(



    );

=cut
