#
# App::Fenix Tk Notebook test script
#
use Test2::V0;
use Tk;
use Path::Tiny;

use lib qw( lib ../lib );

use App::Fenix::Notebook;

BEGIN {
    unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
        plan skip_all => 'Needs DISPLAY';
        exit 0;
    }
    eval { use Tk; };
    if ($@) {
        plan( skip_all => 'Perl Tk is required for this test' );
    }
}

my $mw = tkinit;
$mw->geometry('500x400+20+20');

my ( $delay, $milisec ) = ( 1, 1000 );

ok my $nb = App::Fenix::Notebook->new(
    frame => $mw,
), 'new notebook instance';
isa_ok $nb, ['App::Fenix::Notebook'], 'isa notebook instance';
ok $nb->make, 'make notebook';

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $nb->set_nb_current('lst'), 'raise page lst';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $nb->set_nb_current('det'), 'raise page det';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        ok $nb->set_nb_current('rec'), 'raise page rec';
    }
);

$delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $mw->destroy;
    }
);

Tk::MainLoop;

done_testing;
