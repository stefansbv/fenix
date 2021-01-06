#
# App::Fenix Tk Photograph test script
#
use Test::Most;
use Tk;
use Path::Tiny;

use lib qw( lib ../lib );

use App::Fenix::Toolbar;

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

subtest 'Toolbar from framework toolbar.yml' => sub {
    my $mw = tkinit;
    $mw->geometry('500x60+20+20');

    my ( $delay, $milisec ) = ( 1, 1000 );

    my $yaml_file = path(qw(share etc toolbar.yml));

    ok my $tb = App::Fenix::Toolbar->new(
        frame        => $mw,
        toolbar_file => $yaml_file,
      ),
      'create toolbar instance';

    ok $tb->make, 'make toolbar';

    $mw->after(
        $delay * $milisec,
        sub {
            ok $tb->set_tool_state( 'tb_fm', 'normal' ), 'tb_fm enabled';
            ok $tb->set_tool_state( 'tb_sv', 'normal' ), 'tb_sv enabled';
        }
    );

    $delay++;

    $mw->after(
        $delay * $milisec,
        sub {
            ok $tb->set_tool_state( 'tb_fm', 'disabled' ), 'tb_fm disabled';
            ok $tb->set_tool_state( 'tb_sv', 'disabled' ), 'tb_sv disabled';
            ok $tb->set_tool_state( 'tb_at', 'disabled' ), 'tb_at disabled';
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
};

subtest 'Toolbar from application toolbar.yml' => sub {
    my $mw = tkinit;
    $mw->geometry('500x60+20+20');

    my ( $delay, $milisec ) = ( 1, 1000 );

    my $yaml_file = path( qw(share apps test-tk etc toolbar.yml) );

    ok my $tb = App::Fenix::Toolbar->new(
        frame        => $mw,
        toolbar_file => $yaml_file,
        side         => 'bottom',
        filter       => [qw{tb2ad tb2sv}],
      ),
      'create toolbar instance';

    ok $tb->make, 'make toolbar';

    $mw->after(
        $delay * $milisec,
        sub {
            ok $tb->set_tool_state( 'tb2ad', 'normal' ), 'tb2ad enabled';
            ok $tb->set_tool_state( 'tb2sv', 'normal' ), 'tb2sv enabled';
        }
    );

    $delay++;

    $mw->after(
        $delay * $milisec,
        sub {
            ok $tb->set_tool_state( 'tb2ad', 'disabled' ), 'tb2ad disabled';
            ok $tb->set_tool_state( 'tb2sv', 'disabled' ), 'tb2sv disabled';
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
};

done_testing;
