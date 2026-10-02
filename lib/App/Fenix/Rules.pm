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
        {   idle => {
                state      => 'disabled',
                background => 'disabled_bgcolor',
            },
            add => {
                state      => 'normal',
                background => 'from_config',
            },
            find => {
                state      => 'normal',
                background => 'lightgreen',
            },
            edit => {
                state      => 'from_config',
                background => 'from_config',
            },
            sele => {
                state      => 'from_config',
                background => 'from_config',
            },
        }
    },
    handles => { get_rules => 'get' },
);

1;
