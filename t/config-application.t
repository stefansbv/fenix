use utf8;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config;
use App::Fenix::Config::Application;

my $args = {
    mnemonic => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

ok my $conf = App::Fenix::Config->new($args), 'constructor';

is $conf->sharedir, 'share', 'share dir';

my $rx = qr{etc/};
like $conf->application_file, qr/${rx}application\.yml$/, 'application config file (yml) path';

ok my $cm = App::Fenix::Config::Application->new(
    application_file => $conf->application_file,
), 'new application config';

like(
    dies { $cm->get_application_limits },
    qr/get_application_limits: requires a 'name' parameter/,
    "throws get_application_limits: requires a 'name' parameter"
);

like(
    dies { $cm->get_application_limits('unknown') },
    qr/The application 'unknown' configuration was not found/,
    "throws: the 'unknown' configuration was not found!"
);

is $cm->get_application('widgetset'), 'Tk', 'widgetset';
is $cm->get_application('module'), 'Test', 'module';
is $cm->get_application('dateformat'), 'usa', 'dateformat';

is $cm->get_application('unknown'), undef, 'unknown config returns undef';

done_testing;
