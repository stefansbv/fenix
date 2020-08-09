package App::Fenix::Target;

# ABSTRACT: Fenix database target

use Moo;
#use Locale::TextDomain qw(App-Fenix);
use URI::db;
use App::Fenix::Types qw(
    Str
    FenixEngine
    URIdb
);
use namespace::autoclean;

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    lazy     => 0,
    default  => sub { '' },
);

sub target { shift->name }

has uri => (
    is       => 'ro',
    isa      => URIdb,
    required => 1,
    coerce      => sub {
        my $uri_str = shift;
        return URI::db->new($uri_str);
    },
    handles  => {
        engine_key => 'canonical_engine',
        dsn        => 'dbi_dsn',
        username   => 'user',
        password   => 'password',
    },
);

has engine => (
    is      => 'ro',
    isa     => FenixEngine,
    lazy    => 1,
    default => sub {
        my $self = shift;
        require App::Fenix::Engine;
        return App::Fenix::Engine->load( {
            target => $self,
        } );
    },
);

1;

__END__

=encoding utf8

=head1 NAME

Fenix::Target - Fenix database target

=head1 SYNOPSIS

  my $target = App::Fenix::Target->new(
      uri => 'db:...',
  );

=head1 DESCRIPTION

App::Fenix::Target provides the L<engine|Fenix::Engine>
required to carry out Fenix commands.  All commands should
instantiate a target to work with a database.

=head1 INTERFACE

=head3 C<new>

  my $target = App::Fenix::Target->new( fenixdev => $fenixdev );

Instantiates and returns an App::Fenix::Target object. The
parameters are C<name> and C<uri>.

=head2 ACCESSORS

=head3 C<name>

=head3 C<target>

  my $name = $target->name;
  $name = $target->target;

The name of the database target configuration.  If there was no name
specified, the URI will be used (minus the password, if there is one).

=head3 C<uri>

  my $uri = $target->uri;

The L<URI::db> object encapsulating the database connection information.

=head3 C<engine>

  my $engine = $target->engine;

A L<App::Fenix::Engine> object to use for database interactions with the
target.

=head3 C<engine_key>

  my $key = $target->engine_key;

The key defining which engine to use. This value defines the class loaded by
C<engine>. Convenience method for C<< $target->uri->canonical_engine >>.

=head3 C<dsn>

  my $dsn = $target->dsn;

The DSN to use when connecting to the target via the DBI. Convenience method
for C<< $target->uri->dbi_dsn >>.

=head3 C<username>

  my $username = $target->username;

The username to use when connecting to the target via the DBI. Convenience
method for C<< $target->uri->user >>.

=head3 C<password>

  my $password = $target->password;

The password to use when connecting to the target via the DBI.
Convenience method for C<< $target->uri->password >>.

=head1 SEE ALSO

=over

=item L<fenixdev>

The FenixDev command-line client.

=back

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

Ștefan Suciu <stefan@s2i2.ro>

=head1 LICENSE

Copyright (c) 2012-2014 iovation Inc.

Copyright (c) 2016 Ștefan Suciu.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
