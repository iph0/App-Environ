use 5.008000;
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 6;
use Test::Fatal;
use App::Environ;
use AnyEvent;

BEGIN {
  $ENV{APPCONF_DIRS} = 't/etc';
}

use Foo;
use Bar;

t_initialize();
t_reload();
t_finalize();


sub t_initialize {
  ev_loop(
    sub {
      my $cv = shift;

      App::Environ->send_event('initialize', 'arg1', 'arg2',
        sub {
          $cv->send;
        }
      );
    }
  );

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
  ev_loop(
    sub {
      my $cv = shift;

      App::Environ->send_event( 'reload',
        sub {
          $cv->send;
        }
      );
    }
  );

  my $t_foo_inst = Foo->instance;
  my $t_bar_inst = Bar->instance;

  is( $t_foo_inst->{reload_cnt}, 1, 'reload; Foo' );
  is( $t_bar_inst->{reload_cnt}, 1, 'reload; Bar' );

  return;
}

sub t_finalize {
  ev_loop(
    sub {
      my $cv = shift;

      App::Environ->send_event( 'finalize:r',
        sub {
          $cv->send;
        }
      );
    }
  );

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

sub ev_loop {
  my $sub = shift;

  my $cv = AE::cv;

  $sub->($cv);

  my $timer = AE::timer( 10, 0,
    sub {
      diag( 'Emergency exit from event loop.' );
      $cv->send;
    }
  );

  $cv->recv;

  return;
}
