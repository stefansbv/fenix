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

    is $status->is_state('gui_state', 'unknown'), undef, "is state unknown undefined";

    throws_ok { $status->get_state() }
        qr/\Qget_state: required params/,
        qq{'get_state' should have been called with one param};

    throws_ok { $status->get_state('unknown_state') }
        qr/\Qget_state: unknown_state state not implemented/,
        qq{'unknown_state' should not be a valid state};

    throws_ok { $status->is_state() }
        qr/\Qis_state: required params/,
        qq{'is_state' should have been called with two params};

    throws_ok { $status->is_state('gui_state') }
        qr/\Qis_state: required params/,
        qq{'is_state' should have been called with two params};

    throws_ok { $status->is_state('unknown_state', 'idle') }
        qr/\Qis_state: unknown_state state not implemented/,
        qq{'unknown_state' should not be a valid state};

    throws_ok { $status->set_state('gui_state', 'unknown') }
        qr/\QValue "unknown" did not pass type constraint "Enum[idle,init,work]"/,
        qq{'unknown' should not be a valid mode for the gui_state};
};

done_testing;
