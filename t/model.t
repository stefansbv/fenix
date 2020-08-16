#
# Test the Model
#
use Test2::V0;
use Path::Tiny;

use App::Fenix::Config;
use App::Fenix::Model;

my $args = {
    mnemonic => 'test-tk',
    user     => 'user',
    pass     => 'pass',
    cfpath   => 'share/',
};

ok my $config = App::Fenix::Config->new($args), 'constructor';
isa_ok $config, ['App::Fenix::Config'], 'Fenix::Config';

ok my $cc = $config->connection_config, 'config  connection';
isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
#is $cc->driver, 'sqlite', 'the engine';
is $cc->dbname, 'classicmodels.db', 'the dbname';

ok my $model = App::Fenix::Model->new( config => $config, ),
    'new model instance';
isa_ok $model, ['App::Fenix::Model'], 'the Model';
isa_ok $model->config, ['App::Fenix::Config'], 'config';

is $model->verbose, 0, 'verbose config';
is $model->debug,   0, 'debug config';

isa_ok $model->db, ['App::Fenix::Model::DB'], 'db model';

isa_ok $model->db->target, ['App::Fenix::Target'], 'target';

isa_ok $model->db->target->engine->dbh, ['DBI::db'], 'db';

isa_ok $model->db->dbh, ['DBI::db'], 'dbh';


done_testing;
