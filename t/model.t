#
# Test the Model
#
use 5.010;
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Time::Moment;

use App::Fenix::Config;
use App::Fenix::Model;

ok my $conf = App::Fenix::Config->new, 'new config instance';
isa_ok $conf, 'App::Fenix::Config', 'GUI::Config';

ok my $model = App::Fenix::Model->new(
    config => $conf,
), 'new model instance';
isa_ok $model, 'App::Fenix::Model', 'GUI::Model';

done_testing;
