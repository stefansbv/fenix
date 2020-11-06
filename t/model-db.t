#
# Test the Model::DB
#
use Test2::V0;
use Test2::Tools::Subtest qw/subtest_streamed/;

use App::Fenix::Config;
use App::Fenix::Model::DB;

use Data::Dump qw/dump/;
my $args = {
    mnemonic => 'test-tk',
    user     => 'user',
    pass     => 'pass',
    cfpath   => 'share/',
};

ok my $config = App::Fenix::Config->new($args), 'constructor';
isa_ok $config, ['App::Fenix::Config'], 'Fenix::Config';
ok my $cc = $config->connection, 'config  connection';
isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';

subtest_streamed 'Model DB without parameters' => sub {
    like(
        dies { my $db = App::Fenix::Model::DB->new },
        qr/\QMissing required arguments:/,
        'Should get an exception for missing params'
    );
};

subtest_streamed 'Model DB with URI' => sub {
    ok my $db = App::Fenix::Model::DB->new(
        config => $config,
    ), 'new db instance';

    ok my $cc = $config->connection, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'sqlite', 'the engine';
    is $cc->dbname, 'classicmodels.db', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels\.db$/, 'the uri';

    isa_ok $db, ['App::Fenix::Model::DB'], 'Model::DB';

    isa_ok $db->target, ['App::Fenix::Target'], 'target';
    isa_ok $db->target->engine->dbh, ['DBI::db'], 'db';

    like(
        dies { $db->cmp_function },
        qr/\Qcmp_function: missing required arguments:/,
        'Should get an exception for missing params'
    );
    is $db->cmp_function('%model%'), '-LIKE', 'compare function';

    # query_record
    my $opts = {
        table   => 'products',
        columns => undef,
        where   => { productcode => "S10_1678" },
    };
    ok my $rec = $db->query_record($opts), 'query';
    is( $rec,
        hash {
            field buyprice           => match qr/\d+/;
            field msrp               => match qr/\d+/;
            field productcode        => match qr/\w\d+/;
            field productdescription => match qr/[\w\s]+/;
            field productlinecode    => match qr/\d+/;
            field productname        => match qr/[\w\s]+/;
            field productscale       => match qr/1:\d+/;
            field productvendor      => match qr/[\w\s]+/;
            field quantityinstock    => match qr/\d+/;
            end;    # no more elements.
        },
        'the record should match'
    );

    # build_sql_where
    $opts = {
      where   => { fact_inreg => ["2020.10", "date"], id_firma => [1, "full"] },
    };
    # where:
    # {
    #   fact_inreg => { -extractmonth => [10], -extractyear => [2020] },
    #   id_firma   => 1,
    # }
    ok my $where = $db->build_sql_where($opts), 'build_sql_where';
    is( $where,
        hash {
            field fact_inreg => hash {
                field '-extractmonth' => array { item   10; end; };
                field '-extractyear'  => array { item 2020; end; };
                end;
            };
            field id_firma   => match qr/\d+/;
            end;    # no more elements.
        },
        'the where record should match'
    );
};


done_testing;
