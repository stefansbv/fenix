package App::Fenix::Tk::App::Demo;

# ABSTRACT: The main module of the Fenix demo application

use strict;
use warnings;

sub application_name {
    my $name = "Demo application for Fenix\n";
    $name .= "Author: Stefan Suciu\n";
    $name .= "Copyright 2010-2021\n";
    $name .= "GNU General Public License (GPL)\n";
    $name .= 'stefan@s2i2.ro';
    return $name;
}

1;
