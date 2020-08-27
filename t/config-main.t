use utf8;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config;
use App::Fenix::Config::Main;

my $args = {
    mnemonic => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

ok my $conf = App::Fenix::Config->new($args), 'constructor';

is $conf->sharedir, 'share', 'share dir';

my $rx = qr{etc/};
like $conf->main_file, qr/${rx}main\.yml$/, 'main config file (yml) path';

ok my $cm = App::Fenix::Config::Main->new(
    main_file => $conf->main_file,
), 'new main config';

# externalapps

like(
    dies { $cm->get_apps_exe_path },
    qr/get_apps_exe_path: requires a 'name' parameter/,
    "throws get_apps_exe_path: requires a 'name' parameter"
);

like(
    dies { $cm->get_apps_exe_path('unknown') },
    qr/The externalapps 'unknown' configuration was not found/,
    "throws: the 'unknown' configuration was not found!"
);

is $cm->get_apps_exe_path('chm_viewer'), '/usr/bin/okular', 'get_apps_exe_path';

# resource

like(
    dies { $cm->get_resource_path },
    qr/get_resource_path: requires a 'name' parameter/,
    "throws get_resource_path: requires a 'name' parameter"
);

like(
    dies { $cm->get_resource_path('unknown') },
    qr/The resource 'unknown' configuration was not found/,
    "throws: the 'unknown' configuration was not found!"
);

is $cm->get_resource_path('icons'), 'etc/interfaces/icons', 'get_resource_path';

done_testing;
