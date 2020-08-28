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

my $rx = qr{etc/};
like $conf->menubar_file, qr/${rx}menubar\.yml$/,
  'menubar config file (yml) path';

my $expected_menu = {
    id        => '5009',
    label     => 'Help',
    underline => 0,
    popup     => {
        1 => {
            key       => undef,
            label     => 'Manual',
            name      => 'mn_gd',
            sep       => 'none',
            underline => 0,
        },
        2 => {
            key       => undef,
            label     => 'About',
            name      => 'mn_ab',
            sep       => 'none',
            underline => 0,
        },
    },
};

ok my $tb = App::Fenix::Config::Menubar->new(
    menubar_file => $conf->menubar_file,
), 'new menubar config';
ok my @menus = sort( $tb->all_menus ), 'get all menus';
is \@menus, [qw(menu_admin menu_app menu_help)], 'menu names match';
is $tb->get_menu('menu_help'), $expected_menu, 'the app menu props';

done_testing;
