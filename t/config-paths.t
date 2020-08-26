use 5.010001;
use utf8;
use Path::Tiny;
use Cwd;
use Test2::V0;

use App::Fenix::Config::Paths;

subtest 'Existing distribution context, good CWD' => sub {
    ok my $info = App::Fenix::Config::Paths->new( mnemonic => 'test-tk' ),
      'new instance';

    is $info->mnemonic, 'test-tk', 'the mnemonic';

    like $info->dist_sharedir, qr/apps$/,      'the dist share rel path';
    like $info->configdir,     qr/\.?fenix$/i, 'the app config abs path';
    like(
        dies { $info->user_path_for },
        qr/No parameter/,
        'To few parameters for user_path_for'
    );
    like $info->user_path_for('etc'), qr/etc$/, 'the etc user config path';
    ok $info->exists_user_path_for('etc'), 'exists etc user config path';
    like(
        dies { $info->dist_path_for },
        qr/No parameter/,
        'To few parameters for dist_path_for'
    );
    like $info->dist_path_for('etc'), qr/etc$/, 'the etc dist config path';
    is $info->exists_dist_path_for('etc'), 1, 'exists the etc dist config path';
};

done_testing;
