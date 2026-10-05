#
# Test the Ctrl
#
use 5.010;
use Test2::V0;
use Tk;
use Tk::widgets qw(JComboBox DateEntry);

use App::Fenix::Ctrl;

my $mw = Tk::MainWindow->new;

subtest 'Test Ctrl with a Text widget' => sub {
    my $tlogger = $mw->Scrolled(
        'Text',
    );

    my $c = App::Fenix::Ctrl->new(
        name => 'logger',
        type => 't',
        ctrl => $tlogger,
    );

    is $c->name, 'logger', 'the name attrib';
    is $c->type, 't',      'the type attrib';
    isa_ok $c->ctrl->Subwidget('scrolled'), ['Tk::Text'], 'the ctrl attrib';

};

subtest 'Test Ctrl with a JComboBox widget' => sub {

    my $vstatuscode;
    my $bstatuscode = $mw->JComboBox(
        -textvariable => \$vstatuscode,
    );

    my $c = App::Fenix::Ctrl->new(
        name     => 'jcombo',
        type     => 'c',
        variable => \$vstatuscode,
        ctrl     => $bstatuscode,
    );

    is $c->name, 'jcombo', 'the name attrib';
    is $c->type, 'c',      'the type attrib';
    isa_ok $c->ctrl, ['Tk::JComboBox'], 'the ctrl attrib';

};

subtest 'Test Ctrl with a DateEntry widget' => sub {

    my $vorderdate;
    my $dorderdate = $mw->DateEntry(
        -variable => \$vorderdate,
    );

    my $c = App::Fenix::Ctrl->new(
        name     => 'date',
        type     => 'd',
        variable => \$vorderdate,
        ctrl     => $dorderdate,
    );

    is $c->name, 'date', 'the name attrib';
    is $c->type, 'd',    'the type attrib';
    isa_ok $c->ctrl, ['Tk::DateEntry'], 'the ctrl attrib';

};

done_testing;
