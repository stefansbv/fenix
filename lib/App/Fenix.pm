package App::Fenix;

# ABSTRACT: GUI

use 5.010;
use Moo;
use App::Fenix::Types qw(
    FenixController
);
use App::Fenix::Controller;

has 'controller' => (
    is      => 'rw',
    isa     => FenixController,
    lazy    => 1,
    builder => '_build_controller',
);

sub _build_controller {
    return App::Fenix::Controller->new();
}

sub run {
    shift->controller->view->MainLoop;
}

1;

=head1 AUTHOR

Stefan Suciu, C<< <stefan@s2i2.ro> >>

=head1 BUGS

None known.

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGMENTS

The implementation of the localization code is based on the work of
David E. Wheeler.

Thank you!

=head1 LICENSE AND COPYRIGHT

  Stefan Suciu       2020

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation.

=cut
