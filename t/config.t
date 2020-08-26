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
        user   => 'user',
        pass   => 'pass',
        cfpath => 'share/',
    };

    ok my $conf = App::Fenix::Config->new($args), 'constructor';

    like $conf->user_path_for('etc'), qr/etc$/, 'the etc user config path';

    is $conf->mnemonic, 'test-tk', 'mnemonic (mnemonic)';
    is $conf->user,   'user',    'user';
    is $conf->pass,   'pass',    'pass';
    is $conf->cfpath, 'share/',  'cfpath is defined';

    my $rx = ( $^O eq 'MSWin32' )
        ? qr{etc\\}
        : qr{etc/};
    like $conf->main_file, qr/${rx}main\.yml$/, 'main config file (yml) path';
    like $conf->default_file, qr/${rx}default\.yml$/,
        'default config file (yml)';
    like $conf->xresource, qr/${rx}xresource\.xrdb$/, 'xresource file';

    $rx = ( $^O eq 'MSWin32' )
        ? qr{apps\\test-tk\\etc\\}
        : qr{apps/test-tk/etc/};
    like $conf->connection_file, qr/${rx}connection\.yml$/, 'connection config file';

    ok my $cc = $conf->connection, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'sqlite', 'the engine';
    is $cc->dbname, 'classicmodels.db', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels\.db$/, 'the uri';

    # is $conf->get_apps_exe_path('chm_viewer'), '/usr/bin/okular',
    #     'get_apps_exe_path';

    # is $conf->log_file_path, 'share/etc/log.conf', 'log_file_path';
    # like $conf->log_file_name, qr/fenix\.log$/, 'log_file_name';

};

subtest 'Test Config test-tk, sharedir = dist-dir' => sub {
    my $args = {
        mnemonic => 'test-tk',
        user   => 'user',
        pass   => 'pass',
    };

    ok my $conf = App::Fenix::Config->new($args), 'constructor';

    like $conf->user_path_for('etc'), qr/etc$/, 'the etc user config path';

    is $conf->mnemonic, 'test-tk', 'mnemonic (mnemonic)';
    is $conf->user,   'user',    'user';
    is $conf->pass,   'pass',    'pass';
    is $conf->cfpath, undef,  'cfpath is not defined';

    my $rx = ( $^O eq 'MSWin32' )
        ? qr{etc\\}
        : qr{etc/};
    like $conf->main_file, qr/${rx}main\.yml$/, 'main config file (yml) path';
    like $conf->default_file, qr/${rx}default\.yml$/,
        'default config file (yml)';
    like $conf->xresource, qr/${rx}xresource\.xrdb$/, 'xresource file';

    $rx = ( $^O eq 'MSWin32' )
        ? qr{apps\\test-tk\\etc\\}
        : qr{apps/test-tk/etc/};
    like $conf->connection_file, qr/${rx}connection\.yml$/,
        'connection config file';

    ok my $cc = $conf->connection, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'sqlite', 'the engine';
    is $cc->dbname, 'classicmodels.db', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels\.db$/, 'the uri';

    # is $conf->get_apps_exe_path('chm_viewer'), '/usr/bin/okular',
    #     'get_apps_exe_path';

    # is $conf->log_file_path, 'share/etc/log.conf', 'log_file_path';
    # like $conf->log_file_name, qr/fenix\.log$/, 'log_file_name';

};

# subtest 'Test Config test-tk-pg' => sub {
#     my $args = {
#         mnemonic => 'test-tk-pg',
#         user   => 'user',
#         pass   => 'pass',
#         cfpath => 'share/',
#     };

#     ok my $conf = App::Fenix::Config->new($args), 'constructor';

#     is $conf->mnemonic, 'test-tk-pg', 'mnemonic (mnemonic)';
#     is $conf->user,   'user',    'user';
#     is $conf->pass,   'pass',    'pass';
#     is $conf->cfpath, 'share/',  'cfpath';

#     like $conf->main_file, qr/main.yml$/, 'main config file (yml)';
#     like $conf->default_file, qr/default.yml$/, 'default config file (yml)';
#     like $conf->xresource, qr/xresource.xrdb$/, 'xresource';
#     like $conf->connection_file, qr/connection.yml$/, 'connection config file';

#     ok my $cc = $conf->connection, 'config  connection';
#     isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
#     is $cc->driver, 'pg', 'the engine';
#     is $cc->dbname, 'classicmodels', 'the dbname';
#     is $cc->user, undef, 'the user name';
#     is $cc->role, undef, 'the role name';
#     like  $cc->uri, qr/classicmodels$/, 'the uri';

# };

done_testing;
