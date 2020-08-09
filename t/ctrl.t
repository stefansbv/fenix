#
# Test the Ctrl
#
use 5.010;
use Test2::V0;
use Tk;

use App::Fenix::Ctrl;

my $mw = Tk::MainWindow->new;
my $tlogger = $mw->Scrolled(
    'Text',
    -width      => 40,
    -height     => 3,
    -wrap       => 'word',
    -scrollbars => 'e',
    -background => 'lightyellow',
    -relief     => 'flat',
);

my $c = App::Fenix::Ctrl->new(
    name => 'logger',
    type => 't',
    ctrl => $tlogger,
);

is $c->name, 'logger', 'the name attrib';
is $c->type, 't', 'the type attrib';
isa_ok $c->ctrl->Subwidget('scrolled'), ['Tk::Text'], 'the ctrl attrib';

done_testing;
