package App::Fenix::Role::FileUtils;

# ABSTRACT: Role for loading config files

use 5.0100;
use utf8;
use Try::Tiny;
use YAML::Tiny 1.57;                         # errstr deprecated
use File::HomeDir;
use Tie::IxHash::Easy;
use Config::General qw(ParseConfig);
use Locale::TextDomain 1.20 qw(App-Fenix);
use App::Fenix::X qw(hurl);
use Moo::Role;

use App::Fenix::Exceptions;

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

sub get_sqlitedb_filename {
    my ($self, $dbname) = @_;
    die "get_testdb_filename: A 'dbname' parameter is required\n" unless $dbname;
    my $dbpath = path $dbname;
    if ( $dbpath->is_absolute ) {
        return $dbpath->stringify;
    }
    $dbname .= '.db' unless $dbname =~ m{\.db$}i;
    return path( File::HomeDir->my_data, $dbname )->stringify;
}

sub check_path {
    my ($self, $path) = @_;
    die "check_path: A 'path' parameter is required\n" unless $path;
    unless ($path and -d $path) {
        Exception::IO::PathNotFound->throw(
            pathname => $path,
            message  => 'Path not found',
        );
    }
    return;
}

sub check_file {
    my ($self, $file) = @_;
    die "check_file: A 'file' parameter is required\n" unless $file;
    unless ($file and -f $file) {
        Exception::IO::FileNotFound->throw(
            filename => $file,
            message  => 'File not found',
        );
    }
    return;
}

no Moo::Role;

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

=head2 get_sqlitedb_filename

Returns the absolute path and file name of the SQLite database.
file.

If the configured path is an absolute path and a file name, retur it,
else make a path from the user data path (as returned by
File::HomeDir), and the configured path and file name.

=head2 check_path

Check a path and throw an exception if not valid.

=head2 check_file

Check a file path and throw an exception if not valid.

=cut
