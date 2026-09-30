#
# App::Fenix Tk Photograph test script
#
use Test2::V0;
use Tk;
use Path::Tiny;

use lib qw( lib ../lib );

use App::Fenix::Config;
use App::Fenix::Config::Screen;
use App::Fenix::Tk::Screen;

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
$mw->geometry('500x60+20+20');

my $args = {
    mnemonic => 'test-tk',
    user     => 'user',
    password => 'pass',
    cfpath   => 'share/',
};

ok my $conf = App::Fenix::Config->new($args), 'new config instance';
isa_ok $conf, ['App::Fenix::Config'], 'isa config instance';

ok my $screen_conf = App::Fenix::Config::Screen->new(
    scrcfg_file => $conf->screen_config_file_path('products') ),
  'new screen config instance';

my ( $delay, $milisec ) = ( 1, 1000 );

ok my $scr = App::Fenix::Tk::Screen->new(
    view   => $mw,
    config => $conf,
    scrcfg => $screen_conf,
), 'new screen instance';
isa_ok $scr, ['App::Fenix::Tk::Screen'], 'isa screen instance';

$mw->after(
    $delay * $milisec,
    sub {
        isa_ok $scr->scrcfg, ['App::Fenix::Config::Screen'],
          'isa screen config';
        # is $scr->get_controls,
        # $scr->get_tm_controls
        # $scr->get_rq_controls
        # $scr->get_toolbar_btn
        # $scr->enable_tool
        is $scr->get_bgcolor, 'white', 'bg color';
        # $scr->make_toolbar_for_table
        # $scr->make_toolbar_in_frame
        # $scr->tmatrix_add_row
        # $scr->tmatrix_remove_row
        # $scr->tmatrix_renumber_rows
        is $scr->date_format, 'usa', 'date format is usa';
        # $scr->app_toolbar_attribs
        # $scr->app_toolbar_names
        # $scr->screen_update
        # $scr->toolscr
    }
);

# $delay++;

$mw->after(
    $delay * $milisec,
    sub {
        $mw->destroy;
    }
);

Tk::MainLoop;

done_testing;
