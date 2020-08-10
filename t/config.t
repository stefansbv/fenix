#
# Test the Config module
#
use Test2::V0;

use Path::Tiny;
#use File::HomeDir;

use App::Fenix::Config;

if ( $^O eq 'MSWin32' ) {
    local $ENV{COLUMNS} = 80;
    local $ENV{LINES}   = 25;
}

subtest 'Test with no config files' => sub {
    my $args = {
        mnemonic => 'test-tk',
        user   => 'user',
        pass   => 'pass',
        cfpath => 'share/',
    };

    ok my $conf = App::Fenix::Config->new($args), 'constructor';

    is $conf->mnemonic, 'test-tk', 'mnemonic (mnemonic)';
    is $conf->user,   'user',    'user';
    is $conf->pass,   'pass',    'pass';
    is $conf->cfpath, 'share/',  'cfpath';

    is $conf->sharedir, 'share', 'sharedir';
    is $conf->xresource, 'share/etc/xresource.xrdb', 'xresource';
};

done_testing;
