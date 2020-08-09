package App::Fenix::Config::Utils;

# ABSTRACT: Config utilities

use feature 'say';
use Moo;
use MooX::HandlesVia;
use Type::Utils qw(enum);
use Try::Tiny;
use App::Fenix::Types qw(
    Path
    FenixConfig
    Maybe
);
use Locale::TextDomain 1.20 qw(App-Fenix);

use App::Fenix::X qw(hurl);
use App::Fenix::Config;

with qw/App::Fenix::Role::FileUtils
        App::Fenix::Role::Utils/;

has config => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has context => (
    is  => 'rw',
    isa => Maybe[enum([qw(
        local
        user
        system
    )])],
    default => sub {
        return 'user';
    },
);

#--

has file => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $meth = ( $self->context || 'local' ) . '_file';
        return $self->config->$meth;
    }
);

has type => ( is => 'ro', isa => enum( [qw(int num bool bool-or-int)] ) );

sub set {
    my ( $self, $key, $value, $rx ) = @_;
    $self->_set( $key, $value, $rx, multiple => 0 );
}

sub add {
    my ( $self, $key, $value ) = @_;
    $self->_set( $key, $value, undef, multiple => 1 );
}

sub replace_all {
    my ( $self, $key, $value, $rx ) = @_;
    $self->_set( $key, $value, $rx, multiple => 1, replace_all => 1 );
}

sub _set {
    my ( $self, $key, $value, $rx, @p ) = @_;
    hurl config => ('Wrong number of arguments.')
        if !defined $key || $key eq '' || !defined $value;

    # $self->_touch_dir;
    try {
        $self->config->set(
            key      => $key,
            value    => $value,
            filename => $self->file,
            filter   => $rx,
            as       => $self->type,
            @p,
        );
    }
    catch {
        hurl config => __(
            'Cannot overwrite multiple values with a single value'
        ) if /^Multiple occurrences/i;
        hurl config => $_;
    };
    return $self;
}

sub unset {
    my ( $self, $key, $rx ) = @_;
    hurl config => ('Wrong number of arguments.')
      if !defined $key || $key eq '';

    # $self->_touch_dir;

    try {
        $self->config->set(
            key      => $key,
            filename => $self->file,
            filter   => $rx,
            multiple => 0,
        );
    }
    catch {
        hurl config => __(
            'Cannot unset key with multiple values'
        ) if /^Multiple occurrences/i;
        hurl config => $_;
    };
    return $self;
}

sub unset_all {
    my ( $self, $key, $rx ) = @_;
    $self->usage('Wrong number of arguments.') if !defined $key || $key eq '';

    #$self->_touch_dir;
    $self->config->set(
        key      => $key,
        filename => $self->file,
        filter   => $rx,
        multiple => 1,
    );
    return $self;
}

sub get {
    my ( $self, $key, $rx ) = @_;
    hurl config => ('Wrong number of arguments.')
      if !defined $key || $key eq '';

    my $val = try {
        $self->config->get(
            key    => $key,
            filter => $rx,
            as     => $self->type,
            human  => 1,
        );
    }
    catch {
        hurl config => __x(
            'More then one value for the key "{key}"',
            key => $key,
        ) if /^\QMultiple values/i;
        hurl config => $_;
    };

    # hurl {
    #     ident   => 'config',
    #     message => '',
    #     exitval => 1,
    # } unless defined $val;

    return $val;
}

sub get_all {
    my ( $self, $key, $rx ) = @_;
    $self->usage('Wrong number of arguments.') if !defined $key || $key eq '';

    my @vals = try {
        $self->config->get_all(
            key    => $key,
            filter => $rx,
            as     => $self->type,
            human  => 1,
        );
    }
    catch {
        hurl config => $_;
    };
    # hurl {
    #     ident   => 'config',
    #     message => '',
    #     exitval => 1,
    # } unless @vals;

    return \@vals;
}

# sub _touch_dir {
#     my $self = shift;
#     unless ( -e $self->file ) {
#         require File::Basename;
#         my $dir = File::Basename::dirname( $self->file );
#         unless ( -e $dir && -d _ ) {
#             require File::Path;
#             File::Path::make_path($dir);
#         }
#     }
# }

sub _prepend {
    my $prefix = shift;
    my $msg = join '', map { $_ // '' } @_;
    $msg =~ s/^/$prefix /gms;
    return $msg;
}

sub emit {
    shift;
    local $|=1;
    say @_;
}

sub comment {
    my $self = shift;
    $self->emit( _prepend '#', @_ );
}

sub dump {
    my $self = shift;
    my $config = $self->config;
    $self->emit("\n");
    $self->comment("Config dump:");
    $self->comment( scalar $config->dump ) if $config;
    return $self;
}


__PACKAGE__->meta->make_immutable;

1;
