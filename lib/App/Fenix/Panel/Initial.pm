package App::Fenix::Panel::Initial;

# ABSTRACT: Panel - Initial

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
    default => sub { 'Initial' },
);

sub _build_panel {
    my $self = shift;

    my $f1d = 50;
    my $f2d = 90;

    #--- Top

    my $top = $self->frame->Frame(
        -background => 'green',
    );
    $top->pack(
        -side   => 'top',
        -expand => 1,
        -fill   => 'x',
    );

    return $self->frame;
}

__PACKAGE__->meta->make_immutable;

1;
