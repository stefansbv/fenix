#!perl -w
##
use strict;
use warnings;
use 5.010;
use Test::More;
use Path::Tiny;
use File::Temp 'tempdir';
use Try::Tiny;
use Test::Exception;
use lib 't/lib';
use DBIEngineTest;

use App::Fenix::Target;

my $CLASS;
my $tmpdir;
my $have_sqlite_driver = 1; # assume DBD::SQLite is installed
my $live_testing   = 0;

# Is DBD::SQLite realy installed?
try { require DBD::SQLite; } catch { $have_sqlite_driver = 0; };

BEGIN {
    $CLASS = 'App::Fenix::Engine::sqlite';
    require_ok $CLASS or die;
}

my $target = App::Fenix::Target->new(
    uri => 'db:sqlite:foo.db',
);
isa_ok my $pg = $CLASS->new( target => $target ),
    $CLASS;

is $pg->uri->dbname, 'foo.db', 'dbname should be filled in';

##############################################################################
# Can we do live tests?

END {
    my %drivers = DBI->installed_drivers;
    for my $driver (values %drivers) {
        $driver->visit_child_handles(sub {
            my $h = shift;
            $h->disconnect if $h->{Type} eq 'db' && $h->{Active};
        });
    }
}

my $tmp_dir = path( tempdir CLEANUP => 1 );
my $db_path = path( $tmp_dir, 'tpda3devtest.db' );
# print "SQLite test db: $db_path\n";
my $uri = "db:sqlite:$db_path";
DBIEngineTest->run(
    class         => $CLASS,
    target_params => [ uri => $uri ],
    skip_unless   => sub {
        my $self = shift;

        # Should have the database handle
        $self->dbh;
    },
    engine_err_regex  => qr/^near "blah": syntax error/,
    test_dbh => sub {
        my $dbh = shift;
        # Make sure foreign key constraints are enforced.
        ok $dbh->selectcol_arrayref('PRAGMA foreign_keys')->[0],
            'The foreign_keys pragma should be enabled';
    },
);

done_testing;
