use 5.010001;
use utf8;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config::Connection;

my $conn_file = path( qw(t connection.yml) );
my $conn_uri  = q(db:pg://localhost:5432/classicmodels);

subtest 'Connection config from yaml file' => sub {
    ok my $cc = App::Fenix::Config::Connection->new(
        connection_file => $conn_file,
    ), 'new instance';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
    is $cc->driver, 'pg', 'the engine';
    is $cc->dbname, 'classicmodels', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels$/, 'the uri';
};

subtest 'Connection config from nonexistent yaml file' => sub {
    ok my $cc = App::Fenix::Config::Connection->new(
        connection_file => path('nonexistent.yaml'),
    ), 'new instance';
    isa_ok $cc, ['App::Fenix::Config::Connection'],'config connection instance';
	like (
		dies { $cc->driver },
		qr/The connection configuration 'nonexistent.yaml' was not found/,
		"throws: connection configuration not found"
	);
};

subtest 'Connection config from URI string' => sub {
    ok my $cc = App::Fenix::Config::Connection->new(
        uri => $conn_uri,
    ), 'new instance';
    like $cc->uri_db, qr/^db:pg/, 'the uri built from a connection file';
    is $cc->driver, 'pg', 'the engine';
    is $cc->host, 'localhost', 'the host';
    is $cc->port, '5432', 'the port';
    is $cc->dbname, 'classicmodels', 'the dbname';
    is $cc->user, undef, 'the user name';
    is $cc->role, undef, 'the role name';
    like  $cc->uri, qr/classicmodels$/, 'the uri';
};

subtest 'Connection config from void' => sub {
    ok my $cc = App::Fenix::Config::Connection->new, 'new instance';
	like (
		dies { $cc->uri_db },
		qr/A connection file or an URI/,
		'a connection file or an URI is expected'
	);
};

done_testing;
