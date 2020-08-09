package App::Fenix::Types;

# ABSTRACT: Tk GUI Types

use 5.010;
use strict;
use warnings;
use utf8;
use Type::Library 0.040 -base, -declare => qw(
    AppLogger
    Path
    FenixCal
    FenixConfig
    FenixConfigMenu
    FenixConfigTool
    FenixConfigUtils
    FenixMenubar
    FenixToolbar
    FenixState
    FenixStatus
    FenixPanel
    FenixNotebook
    FenixOptions
    FenixController
    FenixModel
    FenixRules
    FenixEngine
    FenixTarget
    FenixView
    TkFrame
    TkStatusbar
    TkToolbar
    TkNB
    TkTB
    TkMenu
    MailOutlook
    MailOutlookMessage
    DBIdb
    URIdb
    DBIxConnector
    FenixRecord
    ListCompare
    FenixCompare
);
use Type::Utils -all;
use Types::Standard -types;
use App::Fenix::X qw(hurl);

# Inherit standard types.
BEGIN { extends "Types::Standard" };

class_type FenixView,       { class => 'App::Fenix::View' };
#class_type FenixRules,     { class => 'App::Fenix::Rules' };
class_type FenixCal,        { class => 'App::Fenix::Cal' };
class_type FenixModel,      { class => 'App::Fenix::Model' };
class_type FenixOptions,    { class => 'App::Fenix::Options' };
class_type FenixConfig,     { class => 'App::Fenix::Config' };
class_type FenixConfigMenu, { class => 'App::Fenix::Config::Menubar' };
class_type FenixConfigTool, { class => 'App::Fenix::Config::Toolbar' };
class_type FenixConfigUtils, { class => 'App::Fenix::Config::Utils' };
class_type FenixMenubar,    { class => 'App::Fenix::Menubar' };
class_type FenixToolbar,    { class => 'App::Fenix::Toolbar' };
class_type FenixNotebook,   { class => 'App::Fenix::Notebook' };
class_type FenixRules,      { class => 'App::Fenix::Rules' };
class_type FenixTarget,     { class => 'App::Fenix::Target' };
class_type FenixEngine,     { class => 'App::Fenix::Engine' };
class_type FenixState,      { class => 'App::Fenix::State' };
class_type FenixStatus,     { class => 'App::Fenix::Status' };
class_type FenixPanel,      { class => 'App::Fenix::Panel' };
class_type FenixRecord,     { class => 'App::Fenix::Model::Table::Record' };
class_type FenixCompare,    { class => 'App::Fenix::Model::Update::Compare' };

class_type FenixController, { class => 'App::Fenix::Controller' };
class_type TkStatusbar,     { class => 'Tk::StatusBar' };
class_type TkFrame,         { class => 'Tk::Frame' };
class_type TkMenu,          { class => 'Tk::Menu' };
class_type TkToolbar,       { class => 'Tk::Toolbar' };
class_type TkNB,            { class => 'Tk::NoteBook' };
class_type TkTB,            { class => 'App::Fenix::Tk::TB' };

# Other
class_type AppLogger,          { class => 'Log::Log4perl::Logger' };
class_type Path,               { class => 'Path::Tiny' };
class_type MailOutlook,        { class => 'Mail::Outlook' };
class_type MailOutlookMessage, { class => 'Mail::Outlook::Message' };
class_type DBIdb,              { class => 'DBI::db' };
class_type URIdb,              { class => 'URI::db' };
class_type DBIxConnector,      { class => 'DBIx::Connector' };
class_type ListCompare,        { class => 'List::Compare' };

1;

__END__

=head1 Name

App::Tk::Types - Definition of attribute data types

=head1 Synopsis

  use App::Tk::Types qw(Bool);

=head1 Description

This module defines data types use in Tk object attributes. Supported types
are:

=over

=item C<Tk>

An L<App::Tk> object.

=item C<Engine>

An L<App::Tk::Engine> object.

=item C<Target>

An L<App::Tk::Target> object.

=item C<UserName>

A Tk user name.

=item C<UserEmail>

A Tk user email address.

=item C<Plan>

A L<Tk::App::Plan> object.

=item C<Change>

A L<Tk::App::Plan::Change> object.

=item C<ChangeList>

A L<Tk::App::Plan::ChangeList> object.

=item C<LineList>

A L<Tk::App::Plan::LineList> object.

=item C<Tag>

A L<Tk::App::Plan::Tag> object.

=item C<Depend>

A L<Tk::App::Plan::Depend> object.

=item C<DateTime>

A L<Tk::App::DateTime> object.

=item C<URI>

A L<URI> object.

=item C<URIDB>

A L<URI::db> object.

=item C<File>

A C<Class::Path::File> object.

=item C<Dir>

A C<Class::Path::Dir> object.

=item C<Config>

A L<Tk::App::Config> object.

=item C<DBH>

A L<DBI> database handle.

=back

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 License

Copyright (c) 2012-2015 iovation Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
