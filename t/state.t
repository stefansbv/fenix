use 5.010;
use strict;
use warnings;
use Test::Most;

use App::Fenix;
use App::Fenix::Refresh;

ok my $app = App::Fenix->new, 'new GUI';

ok my $ctrl = $app->controller, 'get the controller';
isa_ok $ctrl, 'App::Fenix::Controller', 'controller';

ok my $view = $ctrl->view, 'get the view';
isa_ok $view, 'App::Fenix::View', 'view';

subtest 'GUI State' => sub {

    use_ok 'App::Fenix::State';

    can_ok 'App::Fenix::State', qw(
        set_state
        get_state
        is_state
    );

    ok my $status = App::Fenix::State->new, 'new GUI status instance';
    isa_ok $status, 'App::Fenix::State', 'GUI status';

    ok my $gui_ref = App::Fenix::Refresh->new( view => $view ),
        'new GUI refresh instance';
    isa_ok $gui_ref, 'App::Fenix::Refresh', 'GUI refresh';

    ok $status->add_observer( $gui_ref ), 'add observer';

    for my $state (qw(init idle work)) {
        ok $status->set_state('gui_state', $state), "set state $state";
        is $status->get_state('gui_state'), $state, "get state ($state)";
        ok $status->is_state('gui_state', $state), "is state $state";
    }

    throws_ok { $status->set_state('gui_state', 'unknown') }
        qr/\QValue "unknown" did not pass type constraint "Enum[idle,init,work]"/,
        qq{'unknown' should not be a valid mode};
};

done_testing;
