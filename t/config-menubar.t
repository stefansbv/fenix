# Test for App::Fenix::Config::Menubar
#
use utf8;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config;
use App::Fenix::Config::Menubar;

my $args = {
    mnemonic => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

ok my $conf = App::Fenix::Config->new($args), 'constructor';

is $conf->sharedir, 'share', 'share dir';
is $conf->menubar_file, path( 'share', 'etc', 'menubar.yml'), 'menubar file';

my $expected_menu = {
    menu_app => {
        id        => '5001',
        label     => 'App',
        underline => 0,
        popup     => {
            1 => {
                name      => 'mn_pr',
                label     => 'Print',
                underline => 0,
                key       => 'Alt-P',
                sep       => 'before',
            },
            2 => {
                name      => 'mn_qt',
                label     => 'Quit',
                underline => '1',
                key       => 'Ctrl+Q',
                sep       => 'before',
            },
        },
    },
};

ok my $tb = App::Fenix::Config::Menubar->new(
    menubar_file => $conf->menubar_file,
), 'new menubar config';
ok my @menus = sort( $tb->all_menus ), 'get all menus';
is \@menus, [qw(menu_app menu_help)], 'menu names match';
is $tb->get_menu('menu_app'), $expected_menu->{menu_app}, 'the app menu props';

done_testing;
