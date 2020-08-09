use 5.010001;
use utf8;
use strict;
use warnings;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config::Toolbar;

my $toolbar_file = path 'share', 'etc', 'toolbar.yml';

my $expected_tool = {
    tb_qt => {
        tooltip => 'Quit',
        help    => 'Quit the application',
        icon    => 'actexit16',
        sep     => 'none',
        type    => '_item_normal',
        id      => '1003',
        state   => {
            'init' => 'normal',
            'idle' => 'normal',
            'work' => 'disabled',
        },
    },
};

ok my $tb = App::Fenix::Config::Toolbar->new(
    toolbar_file => $toolbar_file,
), 'new toolbar config';
ok my @butt = sort( $tb->all_buttons ), 'get all_buttons';
is \@butt, [qw(tb_qt tb_rr tb_sv)], 'tool names match';
is $tb->get_tool('tb_qt'), $expected_tool->{tb_qt}, 'the quit tb props';

done_testing;
