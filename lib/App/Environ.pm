package App::Environ;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw( croak );

my %ACCEPTED_EVENTS;
my %REGISTERED_MODULES;
my %MODULE_SERIAL_NUM;

my $REGISTER_COUNTER = 0;

sub import {
  my $self_class = shift;
  my %events     = @_;

  while ( my ( $event_name, $calling_order ) = each %events ) {
    $ACCEPTED_EVENTS{$event_name} = $calling_order;
  }

  return;
}

sub register {
  my $self_class   = shift;
  my $module_class = shift;
  my %handlers     = @_;

  unless ( defined $module_class ) {
    croak 'Module class must be specified';
  }

  return if $REGISTERED_MODULES{$module_class};

  $MODULE_SERIAL_NUM{$module_class} = $REGISTER_COUNTER++;

  unless ( defined $REGISTERED_MODULES{$module_class} ) {
    $REGISTERED_MODULES{$module_class} = {};
  }

  my $module_handlers = $REGISTERED_MODULES{$module_class};

  while ( my ( $event_name, $handler ) = each %handlers ) {
    next unless defined $ACCEPTED_EVENTS{$event_name};

    unless ( ref( $handler ) eq 'CODE' ) {
      croak "\"$event_name\" handler for \"$module_class\" must be sepcified"
          . " as a code reference";
    }

    $module_handlers->{$event_name} = $handler;
  }

  return;
}

sub push_event {
  my $self_class = shift;
  my $event_name = shift;

  unless ( defined $event_name ) {
    croak 'Event name must be specified';
  }
  unless ( defined $ACCEPTED_EVENTS{$event_name} ) {
    croak "Can't handle unknown event \"$event_name\"";
  }

  my @handlers = map {
    defined $REGISTERED_MODULES{$_}{$event_name}
        ? $REGISTERED_MODULES{$_}{$event_name}
        : ()
  }
  sort { $MODULE_SERIAL_NUM{$a} <=> $MODULE_SERIAL_NUM{$b} }
  keys %REGISTERED_MODULES;

  # Reverse calling order of handlers
  if ( $ACCEPTED_EVENTS{$event_name} ) {
    @handlers = reverse @handlers;
  }

  if ( ref( $_[-1] ) eq 'CODE' ) {
    my $cb = pop @_;

    $self_class->_async_call_handler( \@handlers, [@_], $cb );

    return;
  }

  foreach my $handler (@handlers) {
    $handler->(@_);
  }

  return;
}

sub _async_call_handler {
  my $self_class = shift;
  my $handlers   = shift;
  my $args       = shift;
  my $cb         = shift;

  my $handler = shift @{$handlers};

  unless ( defined $handler ) {
    $cb->();

    return;
  };

  $handler->( @{$args},
    sub {
      $self_class->_async_call_handler( $handlers, $args, $cb );
    }
  );

  return;
}

1;
__END__
=head1 NAME

App::Environ - Simple environ for building complex applications

=head1 SYNOPSIS
  use App::Environ;

  App::Environ->register( $module_class,
    'initialize' => sub { ... },
    'finalize'   => sub { ... },
  );

  use App::Environ
    initialize => 0,
    finalize   => 1;

  App::Environ->push_event( 'initialize', qw( foo bar ) );

  App::Environ->push_event( 'finalize' );

=head1 DESCRIPTION

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015, Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut
