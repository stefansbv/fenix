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
    toolbar_file => $conf->toolbar_file,
), 'new toolbar config';
ok my @butt = sort( $tb->all_buttons ), 'get all_buttons';
is \@butt, [qw(tb_qt tb_rr tb_sv)], 'tool names match';
is $tb->get_tool('tb_qt'), $expected_tool->{tb_qt}, 'the quit tb props';

done_testing;
