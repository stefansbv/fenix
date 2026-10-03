package App::Fenix::Rules;

# ABSTRACT: Rules for buttons

use Moo;
use Sub::HandlesVia;
use namespace::autoclean;

has 'rules' => (
    is       => 'ro',
    traits   => ['Hash'],
    required => 1,
    lazy     => 1,
    default  => sub {
        {   init => {
                state      => 'disabled',
                background => 'disabled_bgcolor',
            },
            idle => {
                state      => 'disabled',
                background => 'disabled_bgcolor',
                method     => 'on_screen_mode_idle',
            },
            add => {
                state      => 'normal',
                background => 'from_config',
                method     => 'on_screen_mode_add',
            },
            find => {
                state      => 'normal',
                background => 'lightgreen',
                method     => 'on_screen_mode_find',
            },
            edit => {
                state      => 'from_config',
                background => 'from_config',
                method     => 'on_screen_mode_edit',
            },
            sele => {
                state      => 'from_config',
                background => 'from_config',
                method     => 'on_screen_mode_sele',
            },
        };
    },
    handles => { get_rules => 'get' },
);

1;
