package App::Environ;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp qw( croak );

my %REGISTERED_EVENTS;
my %MODULES_IDX;


sub register {
  my $self_class   = shift;
  my $module_class = shift;
  my %handlers     = @_;

  unless ( defined $module_class ) {
    croak 'Module class must be specified';
  }

  unless ( exists $MODULES_IDX{$module_class} ) {
    $MODULES_IDX{$module_class} = {};
  }
  my $events_idx = $MODULES_IDX{$module_class};

  while ( my ( $event_name, $handler ) = each %handlers ) {
    if ( exists $events_idx->{$event_name} ) {
      croak qq{"$event_name" handler for "$module_class" already registered};
    }
    $events_idx->{$event_name} = 1;

    unless ( exists $REGISTERED_EVENTS{$event_name} ) {
      $REGISTERED_EVENTS{$event_name} = [];
    }
    if ( $event_name =~ m/\:r$/ ) {
      unshift( @{ $REGISTERED_EVENTS{$event_name} }, $handler );
    }
    else {
      push( @{ $REGISTERED_EVENTS{$event_name} }, $handler );
    }
  }

  return;
}

sub send_event {
  my $self_class = shift;
  my $event_name = shift;

  unless ( defined $event_name ) {
    croak 'Event name must be specified';
  }

  return unless exists $REGISTERED_EVENTS{$event_name};

  my @handlers = @{ $REGISTERED_EVENTS{$event_name} };

  if ( ref( $_[-1] ) eq 'CODE' ) {
    my $cb = pop @_;
    $self_class->_async_call_handler( \@handlers, [@_], $cb );
  }
  else {
    foreach my $handler (@handlers) {
      $handler->(@_);
    }
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

App::Environ - Simple environment to build applications using service locator
pattern

=head1 SYNOPSIS

  use App::Environ;

  # Register handlers in your class

  App::Environ->register( __PACKAGE__,
    initialize => sub {
      my $cb = pop if ref( $_[-1] ) eq 'CODE';
      my @args = @_;

      # handling...
    },
    reload       => sub { ... },
    'finalize:r' => sub { ... },
  );

  # Send events from your application

  # Synchronous interface
  App::Environ->send_event( 'initialize', qw( foo bar ) );
  App::Environ->send_event('reload');
  App::Environ->send_event('finalize:r');

  # Asynchronous interface
  App::Environ->send_event( 'initialize', qw( foo bar ), sub { ... } );
  App::Environ->send_event( 'reload', sub { ... } );
  App::Environ->send_event( 'finalize:r', sub { ... } );

=head1 DESCRIPTION

App::Environ is the simple environment to build applications using service
locator pattern. Allows register different application components that provide
common resources.

=head1 METHODS

=head2 register( $class, \%handlers )

Registers handlers for specified events. When an event have been sent, event
handlers will be processed in order in which they was registered. If you want
that event handlers have been processed in reverse order, add postfix C<:r> to
event name.

=head2 send_event( $event [, @args ] [, $cb->() ] )

Sends specified event. All handlers registered for this event will be processed.

=head1 SEE ALSO

L<App::Environ::Config>

Also see examples from the package to better understand the concept.

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016, Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
