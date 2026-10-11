#
# Test the Codings module
#
use Test2::V0;
use Data::Dump qw/dump/;

use App::Fenix::Config;
use App::Fenix::Model::DB;
use App::Fenix::Codings;

# my $dict_data = [
#     { -name => "Cancelled",  -value => "C" },
#     { -name => "Disputed",   -value => "D" },
#     { -name => "In Process", -value => "P" },
#     { -name => "On Hold",    -value => "H" },
#     { -name => "Resolved",   -value => "R" },
#     { -name => "Shipped",    -value => "S" },
# ];

my $args = {
    mnemonic => 'test-tk',
    user     => 'user',
    pass     => 'pass',
    cfpath   => 'share/',
};

subtest 'Test Codings' => sub {

    ok my $config = App::Fenix::Config->new($args), 'constructor';

    ok my $db = App::Fenix::Model::DB->new( config => $config, ),
        'new db instance';

    ok my $cc = $config->connection, 'config  connection';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'sqlite', 'the engine';
    is $cc->dbname, 'classicmodels.db', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels\.db$/, 'the uri';

    my ( $label_lbl, $value_lbl ) = ( '-name', '-value' );

    my $para = {
        code    => "code",
        default => "not set",
        name    => "description",
        orderby => "",
        table   => "status",
    };

    ok my $c = App::Fenix::Codings->new(
        model_db => $db,
    ), 'new instance';

    my $codes = $c->get_coding_init( 'statuscode', $para, 'm' );
    # dump $codes;
    is(
        $codes,
        array {
            item hash {
                field '-name'  => match qr/[\w\s]/;
                field '-value' => match qr/[\w]/;
                end;
            };
            etc;
        }, 'the records should match'
    );

};

done_testing;
