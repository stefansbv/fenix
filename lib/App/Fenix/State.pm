package App::Fenix::State;

# ABSTRACT: Miscelaneous states

use Moo;
use Type::Utils qw(enum);
use namespace::autoclean;

with 'App::Fenix::Role::Observable';

# GUI state
has gui_state => (
    is       => 'rw',
    isa      => enum([ qw(init idle work) ]),
    required => 1,
    default  => 'init',
);

# connection state
has conn_state => (
    is       => 'rw',
    isa      => enum([ qw(connected not_connected) ]),
    required => 1,
    default  => 'not_connected',
);

sub set_state {
    my ( $self, $which, $state ) = @_;
    die "set_state: required params \$which and \$state!"
      unless $which and $state;
    die "set_state: $which state not implemented!" unless $self->can($which);
    $self->$which($state);
    return $self;
}

sub get_state {
    my ( $self, $which ) = @_;
    die "set_state: required params \$which!" unless $which;
    die "get_state: $which state not implemented!" unless $self->can($which);
    return $self->$which;
}

sub is_state {
    my ( $self, $which, $state ) = @_;    
    die "set_state: required params \$which and \$state!"
      unless $which and $state;
    die "is_state: $which state not implemented!" unless $self->can($which);
    return 1 if $self->gui_state eq $state;
    return $self;
}

after set_state => sub {
    my ($self) = @_;
    $self->notify();
};

1;
