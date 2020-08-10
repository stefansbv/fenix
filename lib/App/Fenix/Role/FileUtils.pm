package App::Fenix::Role::FileUtils;

# ABSTRACT: Role for loading config files

use 5.0100;
use utf8;
use Try::Tiny;
use YAML::Tiny 1.57;                         # errstr deprecated
use Tie::IxHash::Easy;
use Config::General qw(ParseConfig);
use Locale::TextDomain 1.20 qw(App-Fenix);
use App::Fenix::X qw(hurl);
use Moose::Role;

sub load_conf {
    my ($self, $file) = @_;
    my $conf = try {
        Config::General->new(
            -UTF8       => 1,
            -ForceArray => 1,
            -ConfigFile => $file,
        );
    }
    catch {
        hurl conf => __x(
            "Failed to load the file '{file}': {error}",
            file  => $file,
            error => $_,
        );
    };
    my %config = $conf->getall;
    return \%config;
}

sub load_yaml {
    my ($self, $file) = @_;
    my $yaml = try {
        YAML::Tiny->read( $file );
    }
    catch {
        hurl yaml => __x(
            "Failed to load the file '{file}': {error}",
            file  => $file,
            error => $_,
        );
    };
    return $yaml->[0];
}

sub conf_new {
    my $self = shift;
    my $conf = Config::General->new(
        -UTF8        => 1,
        -SplitPolicy => 'equalsign',
        -Tie         => 'Tie::IxHash::Easy',
    );
    return $conf;
}

sub write_yaml {
    my ($self, $file, $data) = @_;
    my $yaml = YAML::Tiny->new($data);
    try   { $yaml->write($file) }
    catch {
        Exception::Config::YAML->throw(
            usermsg => "Failed to write resource file '$file'",
            logmsg  => $_,
        );
    };
    return;
}

no Moose::Role;

1;

__END__

=encoding utf8

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 INTERFACE

=head2 ATTRIBUTES

=head3 sub conf_new

=head2 INSTANCE METHODS

=head3 load_conf

=head3 load_yaml

=head3 conf_new

=cut
