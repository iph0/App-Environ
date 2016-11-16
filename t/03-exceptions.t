use 5.008000;
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 4;
use Test::Fatal;
use App::Environ;
use App::Environ::Config;

t_module_class_not_specified();
t_repeat_registration();
t_event_name_not_specified();
t_config_not_initialized();


sub t_module_class_not_specified {
  like(
    exception {
      App::Environ->register;
    },
    qr/Module class must be specified/,
    'module class not specified'
  );

  return;
}

sub t_repeat_registration {
  like(
    exception {
      App::Environ->register( 'Foo', initialize => sub {} );
      App::Environ->register( 'Foo', initialize => sub {} );
    },
    qr/"initialize" handler for "Foo" already registered/,
    'repeat registration'
  );
}

sub t_event_name_not_specified {
  like(
    exception {
      App::Environ->send_event;
    },
    qr/Event name must be specified/,
    'event name notspecified'
  );

  return;

}

sub t_config_not_initialized {
  like(
    exception {
      App::Environ::Config->instance;
    },
    qr/must be initialized first/,
    'config not initialized'
  );

  return;
}
