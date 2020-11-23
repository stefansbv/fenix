use 5.010001;
use utf8;
use Path::Tiny;
use Cwd;
use Test2::V0;

use lib 't/lib';

use ConfigPaths;

subtest 'Test paths' => sub {
    ok my $conf = ConfigPaths->new( mnemonic => 'test-tk' ),
      'new instance';

    is $conf->mnemonic, 'test-tk', 'the mnemonic';

    note "sharedir is '" . $conf->sharedir . "'";

    like $conf->sharedir, qr/share/,      'the dist share rel path';
    like $conf->configdir, qr/\.?fenix$/i, 'the app config abs path';
    like(
        dies { $conf->app_path_for },
        qr/No parameter/,
        'To few parameters for app_path_for'
    );
    like $conf->app_path_for('etc'), qr/etc$/, 'the etc user config path';
    ok $conf->exists_app_path_for('etc'), 'exists etc user config path';
    like(
        dies { $conf->dist_path_for },
        qr/No parameter/,
        'To few parameters for dist_path_for'
    );
    like $conf->dist_path_for('etc'), qr/etc$/, 'the etc dist config path';
};

done_testing;
