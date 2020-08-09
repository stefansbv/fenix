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
use App::Fenix::Config::Utils;
use App::Fenix::Model;

# protect against user's environment variables (from Sqitch)
delete @ENV{qw( FENIX_CONFIG FENIX_USR_CONFIG FENIX_SYS_CONFIG )};

local $ENV{FENIX_SYS_CONFIG} = path(qw(t data system.conf));
local $ENV{FENIX_USR_CONFIG} = path(qw(t data user.conf));

ok my $conf = App::Fenix::Config->new, 'new config instance';
isa_ok $conf, 'App::Fenix::Config', 'GUI::Config';

ok my $utils = App::Fenix::Config::Utils->new(
    config => $conf,
), 'new config utils instance';

ok my $model = App::Fenix::Model->new(
    config => $conf,
    utils  => $utils,
), 'new model instance';
isa_ok $model, 'App::Fenix::Model', 'GUI::Model';

my ($year, $month) = current_year_month();
is $model->year_i, $year, "this year: $year";
is $model->month_i, sprintf("%02s", $month), "last month $month";

ok $model->year_l(2018), "set the year";
ok $model->month_l(8), "set the month";

is $model->year_l, 2018, "working year";
is $model->month_l, '08', "working month";

done_testing;

sub current_year_month {
    my $tm     = Time::Moment->now;
    my $tm_new = $tm->minus_months(1);
    return ($tm_new->year, $tm_new->month);
}
