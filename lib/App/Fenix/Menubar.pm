package App::Fenix::Menubar;

# ABSTRACT: Tk Menubar Control

use Moo;
use MooX::HandlesVia;
use App::Fenix::Types qw(
    FenixConfig
    FenixConfigMenu
    TkFrame
    TkMenu
);
use Path::Tiny;
use Tk;
# use Locale::TextDomain 1.20 qw(App-Fenix);

use App::Fenix::Config::Menubar;

has 'frame' => (
    is       => 'ro',
    isa      => TkFrame,
    required => 1,
);

has config => (
    is       => 'ro',
    isa      => FenixConfig,
    required => 1,
);

has 'menu_bar' => (
    is      => 'ro',
    isa     => TkMenu,
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->frame->Menu;
    },
);

has '_menus' => (
    is          => 'ro',
    handles_via => 'Hash',
    lazy        => 1,
    default     => sub { {} },
    handles     => {
        get_menu => 'get',
        set_menu => 'set',
    },
);

has 'menu_config' => (
    is      => 'ro',
    isa     => FenixConfigMenu,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $file = path $self->config->sharedir, 'etc', 'menubar.yml';
        return App::Fenix::Config::Menubar->new( menubar_file => $file, );
    },
);

sub make {
    my $self = shift;
    my $conf = $self->menu_config;
    my $poz;
    foreach my $name ( $conf->all_menubar_names ) {
        my $attribs_app = $conf->get_menu($name);
        $poz = $self->make_menus($name, $attribs_app, $poz );
    }
    $self->frame->configure( -menu => $self->menu_bar );
    return;
}

sub make_menus {
    my ( $self, $name, $attribs, $position ) = @_;
    $position //= 1;
    $self->set_menu( $name => $self->menu_bar->Menu( -tearoff => 0 ) );
    my @popups = sort { $a <=> $b } keys %{ $attribs->{popup} };
    foreach my $id (@popups) {
        $self->make_popup_item(
            $self->get_menu($name),
            $attribs->{popup}{$id},
        );
    }
    $self->menu_bar->insert(
        $position,
        'cascade',
        -menu      => $self->get_menu($name),
        -label     => $attribs->{label},
        -underline => $attribs->{underline},
    );
    $position++;
    return $position;
}

sub make_popup_item {
    my ( $self, $menu, $item ) = @_;
    $menu->add('separator') if $item->{sep} eq 'before';
    $self->set_menu( $item->{name} => $menu->command(
        -label       => $item->{label},
        -accelerator => $item->{key},
        -underline   => $item->{underline},
    ) );
    $menu->add('separator') if $item->{sep} eq 'after';
    return;
}

sub get_menu_popup_item {
    my ( $self, $name ) = @_;
    die "Popup item name is required" unless $name;
    warn "Popup item '$name' does not exists"
        unless $self->get_menu($name);
    return $self->get_menu($name);
}

sub set_menu_state {
        my ( $self, $menu, $state ) = @_;
        $self->get_menu_popup_item($menu)->configure( -state => $state );
        return;
}

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 attr1

=head2 INSTANCE METHODS

=head3 meth1

=cut
