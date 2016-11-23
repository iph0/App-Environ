package Bar;

use strict;
use warnings;

use App::Environ;
use App::Environ::Config;
use AnyEvent;
use Carp qw( croak );

App::Environ::Config->register( qw( bar.yml ) );

App::Environ->register( __PACKAGE__,
  initialize   => sub { __PACKAGE__->_initialize(@_) },
  reload       => sub { __PACKAGE__->_reload(@_) },
  'finalize:r' => sub { __PACKAGE__->_finalize(@_) },
);

my $INSTANCE;


sub instance {
  unless ( defined $INSTANCE ) {
    croak __PACKAGE__ . ' must be initialized first';
  }

  return $INSTANCE;
}

sub _initialize {
  my $class = shift;
  my $cb    = pop if ref( $_[-1] ) eq 'CODE';

  my $bar_config = App::Environ::Config->instance->{'bar'};

  $INSTANCE = {
    config     => $bar_config,
    init_args  => [@_],
    reload_cnt => 0,
  };

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _reload {
  my $cb = pop if ref( $_[-1] ) eq 'CODE';

  $INSTANCE->{config} = App::Environ::Config->instance->{'bar'};
  $INSTANCE->{reload_cnt}++;

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _finalize {
  my $cb = pop if ref( $_[-1] ) eq 'CODE';

  undef $INSTANCE;

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

1;
