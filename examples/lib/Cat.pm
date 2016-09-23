package Cat;

use strict;
use warnings;

use App::Environ;
use App::Environ::Config;
use AnyEvent;
use Carp qw( croak );

App::Environ::Config->register( qw( cat.json ) );

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

  my $cb;
  if ( ref( $_[-1] ) eq 'CODE' ) {
    $cb = pop;
  }

  my $cat_config = App::Environ::Config->instance->{'cat'};

  $INSTANCE = {
    config    => $cat_config,
    init_args => [@_],
  };

  print __PACKAGE__ . " initialized\n";

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _reload {
  my $cb;
  if ( ref( $_[-1] ) eq 'CODE' ) {
    $cb = pop;
  }

  $INSTANCE->{config} = App::Environ::Config->instance->{'cat'};

  print __PACKAGE__ . " reloaded\n";

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _finalize {
  my $cb;
  if ( ref( $_[-1] ) eq 'CODE' ) {
    $cb = pop;
  }

  undef $INSTANCE;

  print __PACKAGE__ . " finalized\n";

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

1;
