package App::Fenix::X;

# ABSTRACT: Exception class - borrowed from Sqitch

use 5.010;
use utf8;
use Moo;
use Types::Standard qw(Str Int);
use Sub::Exporter::Util ();
use Throwable 0.200009;
use Sub::Exporter -setup => [qw(hurl)];
use overload '""' => 'as_string';

binmode STDERR, ':utf8';

has message => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has exitval => (
    is      => 'ro',
    isa     => Int,
    default => 2,
);

with qw(
    Throwable
    StackTrace::Auto
);

has ident => (
  is      => 'ro',
  isa     => Str,
  default => 'DEV'
);

has '+previous_exception' => (init_arg => 'previous_exception')
    if Throwable->VERSION < 0.200007;

sub hurl {
    @_ = (
        __PACKAGE__,
        # Always pass $@, as Throwable is unreliable about getting it thanks
        # to hash randomization. Its workaround in v0.200006:
        # https://github.com/rjbs/throwable/commit/596dfbafed970a30324dc21539d4edf2cbda767a
        previous_exception => $@,
        ref $_[0]     ? %{ $_[0] }
            : @_ == 1 ? (message => $_[0])
            :           (ident => $_[0],  message => $_[1])
    );
    goto __PACKAGE__->can('throw');
}

sub as_string {
    my $self = shift;
    join "\n", grep { defined } (
        $self->message,
        $self->previous_exception,
        $self->stack_trace
    );
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;


__END__

=head1 NAME

App::Fenix::X - Fenix Exception class

=head1 SYNOPSIS

  use Locale::TextDomain;
  use App::Fenix::X qw(hurl);
  open my $fh, '>', 'foo.txt' or hurl {
      ident   => 'io',
      message => __x 'Cannot open {file}: {err}", file => 'foo.txt', err => $!,
  };

Developer:

  hurl 'Odd number of arguments passed to burf()' if @_ % 2;

=head1 DESCRIPTION

This module provides implements Fenix exceptions.  Exceptions may be
thrown by any part of the code, and, as long as a command is running,
they will be handled, showing the error message to the user.

=head1 INTERFACE

=head2 FUNCTION

=head3 C<hurl>

Throws an exception.  Pass the parameters as a hash reference, like
so:

  use App::Fenix::X qw(hurl);
  open my $fh, '>', 'foo.txt' or hurl {
      ident   => 'io',
      message => __x 'Cannot open {file}: {err}", file => 'foo.txt', err => $!,
  };

More simply, if all you need to pass are the C<ident> and C<message>
parameters, you can pass them as the only arguments to C<hurl()>:

  open my $fh, '>', 'foo.txt'
    or hurl io => __x 'Cannot open {file}: {err}", file => 'foo.txt', err => $!

For errors that should only happen during development (e.g., an
invalid parameter passed by some other library that should know
better), you can omit the C<ident>:

  hurl 'Odd number of arguments passed to burf()' if @_ % 2;

In this case, the C<ident> will be C<DEV>, which you should not otherwise use.
Fenix will emit a more detailed error message, including a stack trace, when
it sees C<DEV> exceptions.

The supported parameters are:

=over

=item C<ident>

A non-localized string identifying the type of exception.

=item C<message>

The exception message. Use L<Locale::TextDomain> to craft localized messages.

=item C<exitval>

Suggested exit value to use.  Defaults to 2. This will be used if
Fenix handles an exception while a command is running.

=back

=head2 METHODS

=head3 C<as_string>

  my $errstr = $x->as_string;

Returns the stringified representation of the exception.  This value
is also used for string overloading of the exception object, which
means it is the output shown for uncaught exceptions. Its contents are
the concatenation of the exception message, the previous exception (if
any), and the stack trace.

=head1 HANDLING EXCEPTIONS

use L<Try::Tiny> to do exception handling, like so:

  use Try::Tiny;
  try {
      # ...
  } catch {
      die $_ unless eval { $_->isa('App::Fenix::X') };
      $fenix->vent($x_->message);
      if ($_->ident eq 'DEV') {
          $fenix->vent($_->stack_trace->as_string);
      } else {
          $fenix->debug($_->stack_trace->as_string);
      }
      exit $_->exitval;
  };

Use the C<ident> attribute to determine what category of exception it is, and
take changes as appropriate.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 LICENSE

Copyright (c) 2012-2018 iovation Inc.

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
