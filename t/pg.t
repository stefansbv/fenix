#!perl -w
##
use strict;
use warnings;
use 5.010;
use Test::More;
use Path::Class;
use Try::Tiny;
use Test::Exception;
use File::Spec::Functions;
use lib 't/lib';
use DBIEngineTest;

use App::Fenix::Target;

my $CLASS;
my $user;
my $pass;
my $tmpdir;
my $have_pg_driver = 1; # assume DBD::Pg is installed and so is Pg
my $live_testing   = 0;

# Is DBD::Pg realy installed?
try { require DBD::Pg; } catch { $have_pg_driver = 0; };

BEGIN {
    $CLASS = 'App::Fenix::Engine::pg';
    require_ok $CLASS or die;
    $ENV{FENIX_CONFIG}        = 'nonexistent.conf';
    $ENV{FENIX_SYSTEM_CONFIG} = 'nonexistent.user';
    $ENV{FENIX_USER_CONFIG}   = 'nonexistent.sys';
    delete $ENV{PGPASSWORD};
}

my $target = App::Fenix::Target->new(
    uri => 'db:pg:foo.fdb',
);
isa_ok my $pg = $CLASS->new( target => $target ),
    $CLASS;

is $pg->uri->dbname, file('foo.fdb'), 'dbname should be filled in';

##############################################################################
# Can we do live tests?

my $dbh;
END {
    return unless $dbh;
    $dbh->{Driver}->visit_child_handles(sub {
        my $h = shift;
        $h->disconnect if $h->{Type} eq 'db' && $h->{Active} && $h ne $dbh;
    });

    $dbh->do('DROP DATABASE __fenixtest__') if $dbh->{Active};
}

my $err = try {
    $pg->use_driver;
    $dbh = DBI->connect('dbi:Pg:dbname=template1', 'postgres', '', {
        PrintError => 0,
        RaiseError => 1,
        AutoCommit => 1,
    });
    $dbh->do($_) for (
        'CREATE DATABASE __fenixtest__',
        q{ALTER DATABASE __fenixtest__ SET lc_messages = 'C'},
    );
    undef;
}
catch {
    eval { $_->message } || $_;
};

my $uri = 'db:pg://@localhost/__fenixtest__';
DBIEngineTest->run(
    class           => $CLASS,
    target_params   => [ uri => $uri ],
    skip_unless     => sub {
        my $self = shift;
        die $err if $err;
        1;
    },
    engine_err_regex => qr/^ERROR:  /,
    test_dbh         => sub {
        my $dbh = shift;

        # Check the session configuration...
    },
);

done_testing;
