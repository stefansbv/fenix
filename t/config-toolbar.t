# Test for App::Fenix::Config::Toolbar
#
use utf8;
use Path::Tiny;
use Test2::V0;

use App::Fenix::Config::Toolbar;

subtest 'Toolbar from framework toolbar.yml' => sub {
    my $yaml_file = path( qw(share etc toolbar.yml) );
    my $expected_tool = {
        id    => 1013,
        help  => 'Quit the application',
        icon  => 'actexit16',
        sep   => 'after',
        state => {
            det => {
                add  => 'disabled',
                edit => 'normal',
                find => 'disabled',
                idle => 'normal',
                sele => 'disabled',
            },
            rec => {
                add  => 'disabled',
                edit => 'normal',
                find => 'disabled',
                idle => 'normal',
                sele => 'disabled',
            },
        },
        tooltip => 'Quit',
        type    => '_item_normal',
    };

    my $expected_tool_names = [
        qw{
          tb_ad
          tb_at
          tb_fc
          tb_fe
          tb_fm
          tb_gr
          tb_pr
          tb_qt
          tb_rm
          tb_rr
          tb_sv
          tb_tn
          tb_tr
          }
    ];

    ok my $tb =
      App::Fenix::Config::Toolbar->new( toolbar_file => $yaml_file ),
      'new toolbar config';
    ok my @butt = sort( $tb->all_buttons ), 'get all_buttons';
    is \@butt, $expected_tool_names, 'tool names match';
    is $tb->get_tool('tb_qt'), $expected_tool, 'the quit tb props';
};

subtest 'Toolbar from application toolbar.yml' => sub {
    my $yaml_file = path( qw(share apps test-tk etc toolbar.yml) );
    my $expected_tool = {
        id    => 2001,
        help  => 'Add new row in table',
        icon  => 'actitemadd16',
        sep   => 'none',
        state => {
            det => {
                idle => 'disabled',
                add  => 'normal',
                edit => 'normal',
                find => 'disabled',
                sele => 'disabled',
            },
            rec => {
                idle => 'disabled',
                add  => 'normal',
                edit => 'normal',
                find => 'disabled',
                sele => 'disabled',
            },
        },
        tooltip => 'Add new row',
        type    => '_item_normal',
    };

    my $expected_tool_names = [
        qw{
          tb2ad
          tb2rm
          tb2rr
          tb2sv
          }
    ];

    ok my $tb =
      App::Fenix::Config::Toolbar->new( toolbar_file => $yaml_file ),
      'new toolbar config';
    ok my @butt = sort( $tb->all_buttons ), 'get all_buttons';
    is \@butt, $expected_tool_names, 'tool names match';
    is $tb->get_tool('tb2ad'), $expected_tool, 'the add tb2 props';
};

done_testing;
