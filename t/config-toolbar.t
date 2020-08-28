# Test for App::Fenix::Config::Toolbar
#
use utf8;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config;
use App::Fenix::Config::Toolbar;

my $args = {
    mnemonic => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

ok my $conf = App::Fenix::Config->new($args), 'constructor';

is $conf->sharedir, 'share', 'share dir';

my $rx = qr{etc/};
like $conf->toolbar_file, qr/${rx}toolbar\.yml$/,
  'toolbar config file (yml) path';

my $expected_tool = {
    tb_qt => {
        id    => 1013,
        help  => 'Quit the application',
        icon  => 'actexit16',
        sep   => 'after',
        state => {
            det => {
                add  => 'disabled',
                edit => 'normal',
                find => 'disabled',
                idle => 'normal',
                sele => 'disabled',
            },
            rec => {
                add  => 'disabled',
                edit => 'normal',
                find => 'disabled',
                idle => 'normal',
                sele => 'disabled',
            },
        },
        tooltip => 'Quit',
        type    => '_item_normal',
    },
};

my $expected_tool_names = [
    qw{
        tb_ad
        tb_at
        tb_fc
        tb_fe
        tb_fm
        tb_gr
        tb_pr
        tb_qt
        tb_rm
        tb_rr
        tb_sv
        tb_tn
        tb_tr
        }
];

ok my $tb = App::Fenix::Config::Toolbar->new(
    toolbar_file => $conf->toolbar_file,
), 'new toolbar config';
ok my @butt = sort( $tb->all_buttons ), 'get all_buttons';
is \@butt, $expected_tool_names, 'tool names match';
is $tb->get_tool('tb_qt'), $expected_tool->{tb_qt}, 'the quit tb props';

done_testing;
