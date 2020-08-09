use 5.010001;
use utf8;
use strict;
use warnings;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config::Menubar;

my $menubar_file = path 'share', 'etc', 'menubar.yml';

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
    menubar_file => $menubar_file,
), 'new menubar config';
ok my @menus = sort( $tb->all_menus ), 'get all menus';
is \@menus, [qw(menu_app menu_help)], 'menu names match';
is $tb->get_menu('menu_app'), $expected_menu->{menu_app}, 'the app menu props';

done_testing;
