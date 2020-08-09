#
# Test the Config::Utils module
#
use Test2::V0;

use Path::Tiny;
use File::HomeDir;

use App::Fenix::Config::Utils;

if ( $^O eq 'MSWin32' ) {
    local $ENV{COLUMNS} = 80;
    local $ENV{LINES}   = 25;
}

subtest 'Test with config files' => sub {
    local $ENV{Fenix_SYS_CONFIG} = path(qw(t data system.conf));
    local $ENV{Fenix_USR_CONFIG} = path(qw(t data user2.conf));

    ok my $conf = App::Fenix::Config->new, 'constructor';

    ok $conf->load, 'load test config files';
    is scalar @{ $conf->config_files }, 2, '2 config files loaded';

    my $utils = App::Fenix::Config::Utils->new(
        config => $conf,
    );
    is $utils->context, 'user', 'context';
    ok $utils->set('core.test', 'True'), 'config set';
    ok $conf->load, 'reload test config files';
    is $utils->get('core.test'), 'True', 'check core.test';
    ok $conf->load, 'reload test config files';
    ok $utils->unset('core.test'), 'config unset';

    ok $utils->unset_all('message.text'), 'unset all';
    ok $utils->set('message.text', 'Salut'), 'config set';
    ok $utils->add('message.text', 'Ce mai faci?'), 'config add';
};

done_testing;
