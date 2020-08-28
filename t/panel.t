#
# Test the Ctrl
#
use 5.010;
use Test2::V0;

use Tk;
use Tk::widgets qw(Text);

use App::Fenix::Config;
use App::Fenix::Model;
use App::Fenix::Ctrl;
use App::Fenix::View;

{
    package My::Panel;

    use Moo;
    use Types::Standard qw(Int);
    use Tk;
    use Tk::widgets qw(Text);

    with qw/App::Fenix::Role::Panel
            App::Fenix::Role::Element/;

    sub _build_panel {
        my $self    = shift;
        my $tlogger = $self->frame->Scrolled(
            'Text',
            -width      => 40,
            -height     => 3,
            -wrap       => 'word',
            -scrollbars => 'e',
            -background => 'lightyellow',
            -relief     => 'flat',
        );
        $self->add_ctrl(
            'logger',
            App::Fenix::Ctrl->new(
                name => 'logger',
                type => 't',
                ctrl => $tlogger,
            )
        );
        return $self->frame;
    }
}

my $args = {
    mnemonic => 'test-tk',
    user   => 'user',
    pass   => 'pass',
    cfpath => 'share/',
};

ok my $conf = App::Fenix::Config->new($args), 'constructor';
ok my $mw    = Tk::MainWindow->new, 'new MW';
ok my $model = App::Fenix::Model->new(
    config => $conf,
), 'new model instance';
ok my $view  = App::Fenix::View->new(
        config => $conf,
        model  => $model,
    ), 'new view';
ok my $panel = My::Panel->new( view => $view ), 'new panel instance';

ok $panel->_build_panel, 'build panel';

my @ctrls = $panel->all_ctrls;
is \@ctrls, [qw(logger)], 'ctrl names match';

my $c = $panel->get_ctrl('logger');
is $c->name, 'logger', 'the name attrib';
is $c->type, 't', 'the type attrib';
isa_ok $c->ctrl->Subwidget('scrolled'), ['Tk::Text'], 'the ctrl attrib';

done_testing;
