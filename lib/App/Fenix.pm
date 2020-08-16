package App::Fenix;

# ABSTRACT: GUI

use 5.010;
use Moo;
use Log::Any::Adapter;
use Log::Log4perl;
use App::Fenix::Types qw(
    Bool
    FenixController
);
use App::Fenix::Controller;
use namespace::autoclean;

with 'MooX::Log::Any';

Log::Any::Adapter->set('Log4perl');

has 'controller' => (
    is      => 'rw',
    isa     => FenixController,
    lazy    => 1,
    builder => '_build_controller',
    handles => [qw{config debug verbose}],
);

has 'has_logger' => (
    is      => 'rw',
    isa     => Bool,
    default => sub {
        return 0;
    },
);

sub _build_controller {
    return App::Fenix::Controller->new();
}

sub run {
    shift->controller->view->MainLoop;
}

sub _init_logger {
    my $self = shift;
    my $log_fqn = $self->config->log_file_path;
    if ( $log_fqn->is_file ) {
        Log::Log4perl->init( $log_fqn->stringify );
        say "Log file config is '$log_fqn'.\n" if $self->debug;
        $self->log->info("Logging system initialized");
        $self->has_logger(1);
    }
    else {
        say
        "The log file config '$log_fqn' was not found, using the default config.\n"
        if $self->debug;
    }
}

sub BUILD {
    my ( $self, $args ) = @_;
    $self->_init_logger;
    if ( !$self->has_logger ) {
        my $log4p_conf = q(
            log4perl.rootLogger=DEBUG, SCREEN
            log4perl.appender.SCREEN=Log::Log4perl::Appender::Screen
            log4perl.appender.SCREEN.layout=SimpleLayout
            log4perl.appender.SCREEN.Threshold=ERROR
        );
        Log::Log4perl->init( \$log4p_conf );
    }
    return;
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
