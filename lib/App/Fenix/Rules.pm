package App::Fenix::Rules;

# ABSTRACT: Rules for buttons

use Moo;
use MooX::HandlesVia;
use namespace::autoclean;

has 'rules' => (
    is          => 'ro',
    handles_via => 'Hash',
    required    => 1,
    lazy        => 1,
    default     => sub { {
        init => {
            input_panel => {
                anul => 'normal',
                luna => 'normal',
                jud  => 'normal',
            },
            f1_panel => {
                b1calcim => 'disable',
                b1antet  => 'disable',
                b1incarc => 'disable',
                b1mail   => 'disable',
            },
            f2_panel => {
                b2vldpdf => 'disable',
                b2vldxml => 'disable',
                b2text   => 'disable',
                b2mail   => 'disable',
            },
        },
        idle => {
            input_panel => {
                anul => 'normal',
                luna => 'normal',
                jud  => 'normal',
            },
            f1_panel => {
                b1calcim => 'disable',
                b1antet  => 'disable',
                b1incarc => 'disable',
                b1mail   => 'disable',
            },
            f2_panel => {
                b2vldpdf => 'disable',
                b2vldxml => 'disable',
                b2text   => 'disable',
                b2mail   => 'disable',
            },
        },
        work => {
            input_panel => {
                anul => 'disable',
                luna => 'disable',
                jud  => 'disabled',
            },
            f1_panel => {
                b1calcim => 'normal',
                b1antet  => 'normal',
                b1incarc => 'normal',
                b1mail   => 'normal',
            },
            f2_panel => {
                b2vldpdf => 'normal',
                b2vldxml => 'normal',
                b2text   => 'normal',
                b2mail   => 'normal',
            },
        } };
    },
    handles => { get_rules => 'get' },
);

1;
