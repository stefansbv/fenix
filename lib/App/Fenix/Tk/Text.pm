package App::Fenix::Tk::Text;

# ABSTRACT: Subclass of Tk::Text

use strict;
use warnings;

use Tk;
use base qw(Tk::Derived Tk::Text);

Construct Tk::Widget 'MText';

sub ClassInit {
    my ( $class, $mw ) = @_;

    $class->SUPER::ClassInit($mw);

    $mw->bind( $class, '<KeyRelease>', sub { $mw->set_modified_record(); } );

    return;
}

1;

=head1 SYNOPSIS

Create new binding for the L<< <KeyRelease> >> event type.

    use App::Fenix::Tk::Text;

    my $entry = MText->new();

=head2 ClassInit

=cut
