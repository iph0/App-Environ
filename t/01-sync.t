use 5.008000;
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 8;
use Test::Fatal qw( lives_ok exception );
use App::Environ;

BEGIN {
  $ENV{APPCONF_DIRS} = 't/etc';
}

use Foo;
use Bar;

t_initialize();
t_reload();
t_unknown_event();
t_handling_error();
t_finalize();


sub t_initialize {
  App::Environ->send_event( 'initialize', 'arg1', 'arg2' );

  my $t_foo_inst = Foo->instance;
  my $t_bar_inst = Bar->instance;

  is_deeply( $t_foo_inst,
    { config     => {
        param1 => 'foo:value1',
        param2 => 'foo:value2',
      },
      init_args  => [ qw( arg1 arg2 ) ],
      reload_cnt => 0,
    }, 'initialization; Foo' );

  is_deeply( $t_bar_inst,
    { config     => {
        param1 => 'bar:value1',
        param2 => 'bar:value2',
      },
      init_args  => [ qw( arg1 arg2 ) ],
      reload_cnt => 0,
    }, 'initialization; Bar' );

  return;
}

sub t_reload {
  App::Environ->send_event('reload');

  my $t_foo_inst = Foo->instance;
  my $t_bar_inst = Bar->instance;

  is( $t_foo_inst->{reload_cnt}, 1, 'reload; Foo' );
  is( $t_bar_inst->{reload_cnt}, 1, 'reload; Bar' );

  return;
}

sub t_unknown_event {
  lives_ok {
    App::Environ->send_event('unknown');
  }
  'unknown event';

  return;
}

sub t_handling_error {
  eval {
    App::Environ->send_event( 'reload', 1 );
  };

  is( $@, "Some error.\n", 'handling error' );

  return;
}

sub t_finalize {
  App::Environ->send_event('finalize:r');

  like(
    exception {
      my $t_foo_inst = Foo->instance;
    },
    qr/Foo must be initialized first/,
    'finalization; Foo'
  );

  like(
    exception {
      my $t_bar_inst = Bar->instance;
    },
    qr/Bar must be initialized first/,
    'finalization; Bar'
  );

  return;
}
