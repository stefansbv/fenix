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

subtest 'Test Config test-tk, sharedir = share' => sub {
    my $args = {
        mnemonic => 'test-tk',
        user     => 'user',
        password => 'pass',
        cfpath   => 'share/',
    };

    ok my $conf = App::Fenix::Config->new($args), 'constructor';

    like $conf->app_path_for('etc'), qr/etc$/, 'the etc user config path';

    is $conf->mnemonic, 'test-tk', 'mnemonic (mnemonic)';
    is $conf->user,   'user',    'user';
    is $conf->password,   'pass',    'pass';
    is $conf->cfpath, 'share/',  'cfpath is defined';

    like $conf->main_file, 'share/etc/main.yml', 'main config file (yml) path from dist share/';
    like $conf->default_file, 'share/etc/default.yml',
        'default config file (yml) from dist share';
    like $conf->xresource, 'share/etc/xresource.xrdb', 'xresource file from dist share';
    like $conf->log_file_path, 'share/etc/log.conf', 'log_file_path from dist share';
    like $conf->log_file_name, qr/fenix\.log$/, 'log_file_name';
    like $conf->menubar_file, 'share/etc/menubar.yml',
        'menubar config file (yml) path from dist share';

    my $rx = qr{apps/test-tk/etc/};
    like $conf->connection_file, qr/${rx}connection\.yml$/,
      'connection config file';
    like $conf->app_menubar_file, qr/${rx}menu\.yml$/,
        'menubar config file (yml) path';

    ok my $cc = $conf->connection, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'sqlite', 'the engine';
    is $cc->dbname, 'classicmodels.db', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels\.db$/, 'the uri';

    is $conf->get_apps_exe_path('chm_viewer'), '/usr/bin/okular',
        'get_apps_exe_path';
};

subtest 'Test Config test-tk, sharedir = dist-dir' => sub {
    my $args = {
        mnemonic => 'test-tk',
        user     => 'user',
        password => 'pass',
    };

    ok my $conf = App::Fenix::Config->new($args), 'constructor';

    like $conf->app_path_for('etc'), qr/etc$/, 'the etc user config path';

    is $conf->mnemonic, 'test-tk', 'mnemonic (mnemonic)';
    is $conf->user,   'user',    'user';
    is $conf->password,   'pass',    'pass';
    is $conf->cfpath, undef,  'cfpath is not defined';

    my $rx = qr{(Fenix|.fenix)/etc/};
    like $conf->main_file, qr/${rx}main\.yml$/, 'main config file (yml) path';
    like $conf->default_file, qr/${rx}default\.yml$/,
        'default config file (yml)';
    like $conf->xresource, qr/${rx}xresource\.xrdb$/, 'xresource file';
    like $conf->log_file_path, qr/${rx}log\.conf$/, 'log_file_path';
    like $conf->log_file_name, qr/fenix\.log$/, 'log_file_name';
    like $conf->menubar_file, qr/${rx}menubar\.yml$/,
        'menubar config file (yml) path';

    $rx = qr{apps/test-tk/etc/};
    like $conf->connection_file, qr/${rx}connection\.yml$/,
        'connection config file';
    like $conf->app_menubar_file, qr/${rx}menu\.yml$/,
        'menubar config file (yml) path';

    ok my $cc = $conf->connection, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'sqlite', 'the engine';
    is $cc->dbname, 'classicmodels.db', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels\.db$/, 'the uri';

    is $conf->get_apps_exe_path('chm_viewer'), '/usr/bin/okular',
        'get_apps_exe_path';
};

subtest 'Test Config test-tk-pg' => sub {
    my $args = {
        mnemonic => 'test-tk-pg',
        user     => 'user',
        password => 'pass',
        cfpath   => 'share/',
    };

    ok my $conf = App::Fenix::Config->new($args), 'constructor';

    like $conf->app_path_for('etc'), qr/etc$/, 'the etc user config path';

    is $conf->mnemonic, 'test-tk-pg', 'mnemonic (mnemonic)';
    is $conf->user,   'user',    'user';
    is $conf->password,   'pass',    'pass';
    is $conf->cfpath, 'share/',  'cfpath';

    like $conf->main_file, 'share/etc/main.yml', 'main config file (yml) path from dist share/';
    like $conf->default_file, 'share/etc/default.yml',
        'default config file (yml) from dist share';
    like $conf->xresource, 'share/etc/xresource.xrdb', 'xresource file from dist share';
    like $conf->log_file_path, 'share/etc/log.conf', 'log_file_path from dist share';
    like $conf->log_file_name, qr/fenix\.log$/, 'log_file_name';
    like $conf->menubar_file, 'share/etc/menubar.yml',
        'menubar config file (yml) path from dist share';

    my $rx = qr{apps/test-tk-pg/etc/};
    like $conf->connection_file, qr/${rx}connection\.yml$/,
        'connection config file';
    like $conf->app_menubar_file, qr/${rx}menu\.yml$/,
        'menubar config file (yml) path';

    ok my $cc = $conf->connection, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'pg', 'the engine';
    is $cc->dbname, 'classicmodels', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    is $cc->uri, 'db:pg://localhost:5432/classicmodels', 'the uri';

    is $conf->get_apps_exe_path('chm_viewer'), '/usr/bin/okular',
        'get_apps_exe_path';
};

done_testing;
