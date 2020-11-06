#
# Test the DBUtils role methods
#
use utf8;
use Path::Tiny;
use SQL::Abstract;
use Test2::V0;

use lib 't/lib';

use TestDBUtils;

ok my $u = TestDBUtils->new, 'new instance';

subtest 'test transformations' => sub {
    is $u->get_transformations('datey'), 'year_month', 'get trafo for "datey"';
    is $u->get_transformations('dateiso'), 'date_string', 'get trafo for "dateiso"';
};

subtest 'test dateentry_parse_date' => sub {

    # no date
    is $u->dateentry_parse_date, undef, 'no date parameter';

    # german
    ok my ( $y1, $m1, $d1 ) = $u->dateentry_parse_date( '31.12.2019', 'german' ),
        'parse a date in "german" format';
    is $y1, 2019, 'year';
    is $m1, 12,   'month';
    is $d1, 31,   'day';

    # iso
    ok my ( $y2, $m2, $d2 ) = $u->dateentry_parse_date( '2019-12-31', 'iso' ),
        'parse a date in "iso" format';
    is $y2, 2019, 'year';
    is $m2, 12,   'month';
    is $d2, 31,   'day';

    # default iso
    ok my ( $y3, $m3, $d3 ) = $u->dateentry_parse_date( '2019-12-31' ),
        'parse a date in default "iso" format';
    is $y3, 2019, 'year';
    is $m3, 12,   'month';
    is $d3, 31,   'day';

    # usa
    ok my ( $y4, $m4, $d4 ) = $u->dateentry_parse_date( '12/31/2019', 'usa' ),
        'parse a date in "usa" format';
    is $y4, 2019, 'year';
    is $m4, 12,   'month';
    is $d4, 31,   'day';

    like(
        dies { $u->dateentry_parse_date( '12/31/2019', 'unknown' ) },
        qr/\Qdateentry_parse_date: unknown date format:/,
        'Should get an exception for unknown date format'
    );
};

subtest 'test dateentry_format_date' => sub {

    # german
    ok my $date = $u->dateentry_format_date( 2019, 12, 31, 'german' ),
        'return a date in "german" format';
    is $date, '31.12.2019', 'date in "german" format';

    # iso
    ok $date = $u->dateentry_format_date( 2019, 12, 31, 'iso' ),
        'return a date in "iso" format';
    is $date, '2019-12-31', 'date in "iso" format';

    # iso default
    ok $date = $u->dateentry_format_date( 2019, 12, 31 ),
        'return a date in "iso" format';
    is $date, '2019-12-31', 'date in "iso" format';

    # usa
    ok $date = $u->dateentry_format_date( 2019, 12, 31, 'usa' ),
        'return a date in "usa" format';
    is $date, '12/31/2019', 'date in "usa" format';

    like(
        dies { $u->dateentry_format_date( 2019, 12, 31, 'unknown' ) },
        qr/\Qdateentry_format_date: unknown date format:/,
        'Should get an exception for unknown date format'
    );

    ok $date = $u->dateentry_format_date( 2019, 12, 31, 'usa' ),
        'return a date in "usa" format';

    like(
        dies { $u->dateentry_format_date( undef, 12, 31 ) },
        qr/\Qdateentry_format_date: the/,
        'Should get an exception for missing parameters'
    );
    like(
        dies { $u->dateentry_format_date( 2019, undef, 31 ) },
        qr/\Qdateentry_format_date: the/,
        'Should get an exception for missing parameters'
    );
    like(
        dies { $u->dateentry_format_date( 2019, 12, undef ) },
        qr/\Qdateentry_format_date: the/,
        'Should get an exception for missing parameters'
    );
};

subtest 'test quote4like' => sub {
    is $u->quote4like('testtext'), '%testtext%', 'quote4like: use default';
    is $u->quote4like('testtext', 'S'), 'testtext%', 'quote4like: use default';
    is $u->quote4like('testtext', 'E'), '%testtext', 'quote4like: use default';
};

subtest 'test special_ops' => sub {

    # extractmonth & extractyear
    my $where = {
        fact_inreg => { -extractmonth => [10], -extractyear => [2020] },
        id_firma   => 1,
    };
    my $sql = SQL::Abstract->new( special_ops => $u->special_ops );
    my ( $stmt, @bind ) = $sql->select( 'table', undef, $where );
    like $stmt, qr/SELECT \* FROM table/, 'select * part';
    like $stmt, qr/EXTRACT \(MONTH FROM fact_inreg\) = \?/, 'extract month';
    like $stmt, qr/AND EXTRACT \(YEAR FROM fact_inreg\) = \?/, 'extract year';
    like $stmt, qr/AND id_firma = \?/, 'field id_firma part';
    is \@bind, [ 10, 2020, 1 ], 'bind 3 params';

    # similar_to
    $where = {
        description => { -similar_to => '%(b|d)%' },
    };
    $sql = SQL::Abstract->new( special_ops => $u->special_ops );
    ( $stmt, @bind ) = $sql->select( 'table', undef, $where );
    like $stmt, qr/SELECT \* FROM table/, 'select * part';
    like $stmt, qr/WHERE \( description SIMILAR TO\s+\?\s+\)/, 'similar to';
    is \@bind, ['%(b|d)%'], 'bind 1 params';

    # match
    $where = {
        description => { -match => '%(b|d)%' },
    };
    $sql = SQL::Abstract->new( special_ops => $u->special_ops );
    ( $stmt, @bind ) = $sql->select( 'table', undef, $where );
    like $stmt, qr/SELECT \* FROM table/, 'select * part';
    like $stmt, qr/WHERE \( description ~\s+\?\s+\)/, 'match';
    is \@bind, ['%(b|d)%'], 'bind 1 params';
};

subtest 'test process_date_string' => sub {
    ok my $rez1 = $u->process_date_string('2020-08-29'), 'process iso date string';
    is $rez1, '2020-08-29', 'where href for dateiso';
    ok my $rez2 = $u->process_date_string('2020-08'), 'process iso year month string';
    is $rez2, { '-extractmonth' => ['08'], '-extractyear' => [2020] }, 'where href for datemy';
};

subtest 'test identify_date_string' => sub {
    my $si = qr![-]!;
    my $so = qr![/]|[.]!;
    is $u->identify_date_string('2020-08-29'), 'dateiso:2020-08-29', 'iso date';
    like $u->identify_date_string('08/29/2020'), qr/dateamb:\d{2}$so\d{2}$so\d{4}/, 'ambigous date';
    like $u->identify_date_string('29.08.2020'), qr/dateamb:\d{2}$so\d{2}$so\d{4}/, 'ambigous date';
    is $u->identify_date_string('08.2020'), 'datemy:2020:08', 'month.year';
    is $u->identify_date_string('2020.08'), 'dateym:2020:08', 'year.month';
    is $u->identify_date_string('1993/02'), 'dateym:1993:02', 'year/month';
    is $u->identify_date_string('02/1993'), 'datemy:1993:02', 'month/year';
    is $u->identify_date_string('2020-04'), 'dateym:2020:04', 'year-month';
    is $u->identify_date_string('04-2020'), 'datemy:2020:04', 'month-year';
    like $u->identify_date_string('2020'), qr/datey:\d{4}/, 'year';
    is $u->identify_date_string(''), 'nothing', 'empty string';
    like $u->identify_date_string('29.08.20'), qr/error:/, 'errorneous date';
};

subtest 'test format_query' => sub {
    is $u->format_query('dateiso:2020-08-29'), '2020-08-29', 'iso date';
    is $u->format_query('dateamb:08/29/2020'), '08/29/2020', 'ambigous date ?!';
    ok my $rez1 = $u->format_query('datemy:2020:08'), 'month and year';
    is $rez1, { '-extractmonth' => ['08'], '-extractyear' => [2020] }, 'where href for datemy';
    ok my $rez2 = $u->format_query('dateym:2020:08'), 'year and month';
    is $rez2, { '-extractmonth' => ['08'], '-extractyear' => [2020] }, 'where href for datemy';
    like(
        dies { $u->format_query('unknown') },
        qr/\Qformat_query: unknown transformation directive 'unknown'/,
        'Should get an exception for unknown transformation directive'
    );
    like(
        dies { $u->format_query('error') },
        qr/\QString not identified or empty/,
        'Should get an exception for unidentified date format'
    );
    like(
        dies { $u->format_query() },
        qr/\Qformat_query: the 'type' parameter/,
        'Should get an exception for undefined date format'
    );
};

subtest 'test year_month and date_string' => sub {
    my $r = $u->year_month( '2020', '08' );
    is $r->{'-extractmonth'}, ['08'], 'got -extractmonth';
    is $r->{'-extractyear'},  [2020], 'got -extractyear';
    is $u->date_string('2020-08-29'), '2020-08-29', 'date_string return the parameter';
};

subtest 'test year_month and date_string' => sub {
    is $u->ins_underline_mark('string', 3), 'str&ing', 'ins&ert "&" in string';
    like(
        dies { $u->ins_underline_mark('string') },
        qr/\Qins_underline_mark: the/,
        'Should get an exception for unidentified date format'
    );
    like(
        dies { $u->ins_underline_mark() },
        qr/\Qins_underline_mark: the/,
        'Should get an exception for unidentified date format'
    );
};

subtest 'test deaccent and decode_unless_utf' => sub {
    is $u->deaccent('ăĂãÃâÂîÎșȘşŞțȚţŢ'), 'aAaAaAiIsSsStTtT', 'deaccent';
    is $u->decode_unless_utf('ăĂãÃâÂîÎșȘşŞțȚţŢ'), 'ăĂãÃâÂîÎșȘşŞțȚţŢ', 'decode if not utf-8 !?!';
    is $u->decode_unless_utf('aeiouai'), 'aeiouai', 'decode if not utf-8 !?!';
};

subtest 'test date functions' => sub {
    like $u->dt_today, qr/\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}/, 'date time today';

    # default locale (ro)
    ok my $dt = $u->dt_today(), 'date time instance';
    foreach my $format (qw{abbrev narrow wide}) {
        ok my $months = $u->month_names($format),
          "get $format months";
        like $months->[0], qr/^I|ian/, 'first month matches';

        ok my $days = $u->day_names($format), "get $format days";
        like $days->[0], qr/^L|lun/, 'first day matches';

        my $month = $u->get_month_name( 12, 'wide' );
        is $month, 'decembrie', 'last month name';

        my $day = $u->get_day_name( 1, 'wide' );
        is $day, 'luni', 'first day name';
    }

    # en_GB locale
    my $locale = 'en_GB';
    ok $dt = $u->dt_today($locale), 'date time instance';
    foreach my $format (qw{abbrev narrow wide}) {
        ok my $months = $u->month_names($format, $locale),
          "get $format months";
        like $months->[0], qr/^J|Jan/, 'first month matches';

        ok my $days = $u->day_names($format, $locale),
          "get $format days";
        like $days->[0], qr/^M|Mon/, 'first day matches';

        my $month = $u->get_month_name( 12, 'wide', $locale );
        is $month, 'December', 'last month name';

        my $day = $u->get_day_name( 1, 'wide', $locale );
        is $day, 'Monday', 'first day name';
    }

    is $u->get_month_name(6, 'narrow'), 'I', 'get 6-th month name - narrow';
    is $u->get_month_name(6, 'abbrev'), 'iun.', 'get 6-th month name - abbrev';
    is $u->get_month_name(6, 'wide'), 'iunie', 'get 6-th month name - wide';

    # month
    like(
        dies { $u->get_month_name('unknown') },
        qr/\Qget_month_name: expecting a number for month parameter/,
        'Should get an exception for missing month parameter'
    );
    like(
        dies { $u->get_month_name() },
        qr/\Qget_month_name: missing month parameter/,
        'Should get an exception for missing month parameter'
    );
    like(
        dies { $u->get_month_name(0) },
        qr/\Qget_month_name: wrong month parameter/,
        'Should get an exception for wrong month parameter - 0'
    );
    like(
        dies { $u->get_month_name(13) },
        qr/\Qget_month_name: wrong month parameter/,
        'Should get an exception for wrong month parameter - 13'
    );

    #day
    like(
        dies { $u->get_day_name() },
        qr/\Qget_day_name: missing day parameter/,
        'Should get an exception for out of raange day parameter'
    );
    like(
        dies { $u->get_day_name(0) },
        qr/\Qget_day_name: wrong day parameter/,
        'Should get an exception for out of raange day parameter'
    );
    like(
        dies { $u->get_day_name(8) },
        qr/\Qget_day_name: wrong day parameter/,
        'Should get an exception for out of raange day parameter'
    );
};

done_testing;
