package Foo;

use strict;
use warnings;

use App::Environ;
use App::Environ::Config;
use AnyEvent;
use Carp qw( croak );

App::Environ::Config->register( qw( foo.json ) );

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
  my $class     = shift;
  my $cb        = pop if ref( $_[-1] ) eq 'CODE';

  my $foo_config = App::Environ::Config->instance->{'foo'};

  $INSTANCE = {
    config     => $foo_config,
    init_args  => [@_],
    reload_cnt => 0,
  };

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _reload {
  my $class    = shift;
  my $cb       = pop if ref( $_[-1] ) eq 'CODE';
  my $need_err = shift;

  if ($need_err) {
    my $err = 'Some error.';

    if ( defined $cb ) {
      AE::postpone { $cb->($err) };
      return;
    }

    die "$err\n";
  }

  $INSTANCE->{config} = App::Environ::Config->instance->{'foo'};
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
