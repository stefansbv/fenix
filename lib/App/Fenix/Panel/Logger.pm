package App::Fenix::Panel::Logger;

# ABSTRACT: Panel - Logger

use utf8;
use Moo;
use App::Fenix::Types qw(
    ArrayRef
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

    #--- Bottom

    my $bot = $self->frame->Frame(
        # -background => 'red',
    );
    $bot->pack(
        -side   => 'bottom',
        -expand => 0,
        -fill   => 'x',
    );

    #--- Log

    my $f_log = $bot->LabFrame(
        -label      => 'Log',
        -labelside  => 'acrosstop',
        -foreground => 'blue',
    );
    $f_log->pack(
        -side   => 'bottom',
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -ipadx  => 5,
        -ipady  => 5,
    );

    #-- logger

    my $tlogger = $f_log->Scrolled(
        'Text',
        -width      => 40,
        -height     => 4,
        -wrap       => 'word',
        -scrollbars => 'e',
        -background => 'lightyellow',
        -relief     => 'flat',
    );
    $tlogger->pack(
        -expand => 1,
        -fill   => 'both',
        -padx   => 5,
        -pady   => 5,
    );

    $self->add_ctrl(
        'logger',
        App::Fenix::Ctrl->new(
            name => 'logger',
            type => 't',
            ctrl => $tlogger,
        )
    );

    return $self->frame;
}

__PACKAGE__->meta->make_immutable;

1;
