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

subtest 'Test Config' => sub {
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

    is $conf->connection_file, 'share/apps/test-tk/etc/connection.yml',
        'connection config file';

    ok my $cc = $conf->connection_config, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'sqlite', 'the engine';
    is $cc->dbname, 'classicmodels.db', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels\.db$/, 'the uri';

    is $conf->get_apps_exe_path('chm_viewer'), '/usr/bin/okular',
        'get_apps_exe_path';

};

done_testing;
