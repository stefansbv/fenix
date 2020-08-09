#
# Test the Config module
#
use Test2::V0;

use Path::Tiny;
use File::HomeDir;

use App::Fenix::Config;

if ( $^O eq 'MSWin32' ) {
    local $ENV{COLUMNS} = 80;
    local $ENV{LINES}   = 25;
}

subtest 'Test with no config files' => sub {

    local $ENV{Fenix_SYS_CONFIG} = path(qw(t nonexistent.conf));
    local $ENV{Fenix_USR_CONFIG} = path(qw(t nonexistent.conf));

    ok my $conf = App::Fenix::Config->new, 'constructor';
};

subtest 'Test with empty config files' => sub {
    local $ENV{Fenix_SYS_CONFIG} = path(qw(t data system0.conf));
    local $ENV{Fenix_USR_CONFIG} = path(qw(t data user0.conf));

    ok my $conf = App::Fenix::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';
};

subtest 'Test with minimum system config and empty user config' => sub {
    local $ENV{Fenix_SYS_CONFIG} = path(qw(t data system1.conf));
    local $ENV{Fenix_USR_CONFIG} = path(qw(t data user0.conf));

    ok my $conf = App::Fenix::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';
    is $conf->get_section( section => 'color' ), {},
        'color scheme is empty';
};

subtest 'Test with config files' => sub {
    local $ENV{Fenix_SYS_CONFIG} = path(qw(t data system.conf));
    local $ENV{Fenix_USR_CONFIG} = path(qw(t data user.conf));

    ok my $conf = App::Fenix::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    like $conf->xresource, qr/xresource\.xrdb/,
        'xresource path is from config';
};

subtest 'Test with config files - renamed resource file' => sub {
    local $ENV{Fenix_SYS_CONFIG} = path(qw(t data system.conf));
    local $ENV{Fenix_USR_CONFIG} = path(qw(t data user2.conf));

    ok my $conf = App::Fenix::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    my $scheme_default = {
        info  => 'yellow2',
        warn  => 'blue2',
        error => 'red2',
        done  => 'green2',
    };

    is $conf->get_section( section => 'color' ), $scheme_default,
        'color scheme is from config';
};

done_testing;
