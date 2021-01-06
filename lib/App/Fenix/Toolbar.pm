package App::Fenix::Toolbar;

# ABSTRACT: Tk Toolbar Control

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    ArrayRef
    FenixConfigTool
    TkFrame
    TkTB
    Maybe
    Path
    Str
);
use Hash::Merge;
use Path::Tiny;
use Tk;
# use Locale::TextDomain 1.20 qw(App-Fenix);

use App::Fenix::Tk::TB;
use App::Fenix::Config::Toolbar;

has 'frame' => (
    is       => 'ro',
    isa      => TkFrame,
    required => 1,
);

has 'toolbar_file' => (
    is       => 'ro',
    isa      => Path,
    required => 1,
);

has 'side' => (
    is      => 'ro',
    isa     => Str,
    default => sub { 'top' },
);

has 'filter' => (
    is  => 'ro',
    isa => Maybe[ArrayRef],
);

#---

has 'tb' => (
    is      => 'ro',
    isa     => TkTB,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $tb   = $self->frame->TB(
            -movable       => 0,
            -side          => $self->side,
            -cursorcontrol => 0,
        );
    },
);

has 'config' => (
    is      => 'ro',
    isa     => FenixConfigTool,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return App::Fenix::Config::Toolbar->new(
            toolbar_file => $self->toolbar_file,
        );
    },
);

sub make {
    my $self = shift;
    my $conf = $self->config;
    my @toolbars = $self->filter
        ? @{ $self->filter }
        : $conf->all_toolbar_names;
    foreach my $name (@toolbars) {
        my $attribs = $conf->get_tool($name);
        $self->tb->make_toolbar_button( $name, $attribs );
    }
    $self->tb->set_initial_mode( \@toolbars );
    return $self->tb;
}

sub get_btn {
    my ( $self, $name ) = @_;
    die "Tool name is required" unless $name;
    warn "Tool '$name' does not exists"
        unless $self->config->get_tool($name);
    return $self->tb->get_toolbar_btn($name);
}

sub set_state {
    my ( $self, $btn_name, $state ) = @_;
    $self->tb->enable_tool( $btn_name, $state );
    return $state;
}

sub alter_btn_states {
    my ($self, $tb_scrn_ref) = @_;
    my $tb_orig_ref = $self->config->_toolbar;
    # my $tb_scrn_ref = $self->screen_rec_config->toolbar // {};
    my $merged = Hash::Merge->new('RIGHT_PRECEDENT')
        ->merge( $tb_orig_ref, $tb_scrn_ref );
    $self->config->_toolbar($merged);
    return;
}

1;
