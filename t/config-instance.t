use 5.010001;
use utf8;
use Path::Tiny;
use Test2::V0;
use Data::Dump;

use App::Fenix::Config::Instance;

my $inst_file = path( qw(t configs apps test-cfg etc instance.yml) );

subtest 'Instance config from yaml file' => sub {
    ok my $ci = App::Fenix::Config::Instance->new(
        instance_file => $inst_file,
    ), 'new instance';
    isa_ok $ci, ['App::Fenix::Config::Instance'],'config instance instance';

    ok my $configs = $ci->get_config('geometry'), 'load config geometry';

    is ref $configs, 'HASH', 'geometry config hash';

    is $ci->get_screen('main'), '588x114+1230+101', 'geometry for the main screen';

    ok(
        lives { $ci->save('tranzact', '643x698+944+111') }, "save screen geometry did not die"
    ) or note($@);

};

done_testing;
