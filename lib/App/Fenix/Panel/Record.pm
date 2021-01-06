package App::Fenix::Panel::Record;

# ABSTRACT: Panel - Record

use utf8;
use Moo;
use App::Fenix::Types qw(
    Str
);
use Tk;
use Tk::widgets qw(LabFrame JComboBox);

with qw/App::Fenix::Role::Panel
        App::Fenix::Role::Element/;

has 'name' => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'Record' },
);

sub _build_panel {
    my $self = shift;
    my $f = $self->nb_frame->Frame->pack( -padx => 5, -pady => 5 );
    return $f;
}

__PACKAGE__->meta->make_immutable;

1;
