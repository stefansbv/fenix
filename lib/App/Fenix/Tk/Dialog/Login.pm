package App::Fenix::Tk::Dialog::Login;

# ABSTRACT: Dialog for user name and password

use utf8;
use Moo;
use Locale::TextDomain 1.20 qw(Fenix);
use Tk;
use App::Fenix::Types qw(
    FenixView
);

with 'App::Fenix::Role::Utils';

has 'view' => (
    is       => 'ro',
    isa      => FenixView,
    required => 1,
    handles  => [qw( frame config model )],
);

sub login {
    my ( $self, $message ) = @_;

    my $bg  = $self->frame->cget('-background');
    my $dlg = $self->frame->DialogBox(
        -title   => __ 'Login',
        -buttons => [__ "OK", __ "Cancel"],
    );

    #- Frame

    my $frame = $dlg->LabFrame(
        -foreground => 'blue',
        -label      => __ 'Login',
        -labelside  => 'acrosstop',
    );
    $frame->pack(
        -padx  => 10,
        -pady  => 10,
        -ipadx => 7,
        -ipady => 5,
    );

    #-- User

    my $luser = $frame->Label( -text => __ 'User', );
    $luser->form(
        -top     => [ %0, 0 ],
        -left    => [ %0, 0 ],
        -padleft => 5,
    );
    my $euser = $frame->Entry(
        -width              => 30,
        -background         => 'white',
        -disabledbackground => $bg,
        -disabledforeground => 'black',
    );
    $euser->form(
        -top  => [ '&', $luser, 0 ],
        -left => [ %0,  90 ],
    );

    #-- Pass

    my $lpass = $frame->Label( -text => __ 'Password', );
    $lpass->form(
        -top     => [ $luser, 8 ],
        -left    => [ %0,     0 ],
        -padleft => 5,
    );
    my $epass = $frame->Entry(
        -width              => 30,
        -background         => 'white',
        -disabledbackground => $bg,
        -disabledforeground => 'black',
        -show               => '*',
    );
    $epass->form(
        -top  => [ '&', $lpass, 0 ],
        -left => [ %0,  90 ],
    );

    #-- Message

    my ( $text, $color ) = $message
        ? $self->categorize_message($message)
        : q{};
    $color ||= 'black';

    my $lmessage = $dlg->Label(
        -text       => $text,
        -width      => 44,
        -relief     => 'groove',
        -foreground => $color,
    )->pack(
        -padx => 0,
        -pady => 0,
    );

    $euser->focus;

    # User from parameter
    if ( $self->config->user ) {
        $euser->delete( 0, 'end' );
        $euser->insert( 0, $self->config->user );
        $euser->xview('end');
        $epass->focus;
    }

    my $answer = $dlg->Show();
    my $return_choice = '';

    my @options  = ( N__"OK");
    my $option_y = __( $options[0] );

    if ( $answer eq $option_y ) {
        my $user = $euser->get;
        my $pass = $epass->get;
        $self->config->user($user) if $user;
        $self->config->password($pass) if $pass;
    }
    else {
        $return_choice = 'cancel';
    }

    return $return_choice;
}

1;

=head1 SYNOPSIS

    use App::Fenix::Tk::Dialog::Login;

    my $fd = App::Fenix::Tk::Dialog::Login->new;

    $fd->login($self);

=head2 new

Constructor method.

=head2 login

Show dialog.

=cut
