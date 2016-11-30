package App::Environ;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.14';

use AnyEvent;
use Carp qw( croak );

my %REGISTERED_HANDLERS;
my %MODULES_IDX;


sub register {
  my $class        = shift;
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
    next if exists $events_idx->{$event_name};

    $events_idx->{$event_name} = 1;
    unless ( exists $REGISTERED_HANDLERS{$event_name} ) {
      $REGISTERED_HANDLERS{$event_name} = [];
    }
    if ( $event_name =~ m/\:r$/ ) {
      unshift( @{ $REGISTERED_HANDLERS{$event_name} }, $handler );
    }
    else {
      push( @{ $REGISTERED_HANDLERS{$event_name} }, $handler );
    }
  }

  return;
}

sub send_event {
  my $class      = shift;
  my $event_name = shift;
  my $cb         = pop if ref( $_[-1] ) eq 'CODE';

  unless ( defined $event_name ) {
    croak 'Event name must be specified';
  }

  unless ( exists $REGISTERED_HANDLERS{$event_name} ) {
    if ( defined $cb ) {
      AE::postpone { $cb->() };
    }

    return;
  }

  my @handlers = @{ $REGISTERED_HANDLERS{$event_name} };

  if ( defined $cb ) {
    $class->_process_async( \@handlers, [@_], $cb );
    return;
  }

  foreach my $handler (@handlers) {
    $handler->(@_);
  }

  return;
}

sub _process_async {
  my $class    = shift;
  my $handlers = shift;
  my $args     = shift;
  my $cb       = shift;

  my $handler = shift @{$handlers};

  $handler->( @{$args},
    sub {
      my $err = shift;

      if ( defined $err ) {
        $cb->($err);
        return;
      }

      if ( @{$handlers} ) {
        $class->_process_async( $handlers, $args, $cb );
        return;
      }

      $cb->();
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

  App::Environ->register( __PACKAGE__,
    initialize   => sub { ... },
    reload       => sub { ... },
    'finalize:r' => sub { ... },
  );

  App::Environ->send_event( 'initialize', qw( foo bar ) );
  App::Environ->send_event('reload');
  App::Environ->send_event('finalize:r');

  App::Environ->send_event( 'initialize', qw( foo bar ), sub { ... } );
  App::Environ->send_event( 'reload', sub { ... } );
  App::Environ->send_event( 'finalize:r', sub { ... } );

=head1 DESCRIPTION

App::Environ is the simple environment to build applications using service
locator pattern. Allows register different application components that provide
common resources.

=head1 METHODS

=head2 register( $class, \%handlers )

The method registers handlers for specified events. When some event have been
sent, corresponding to this event handlers will be processed in order in which
they was registered. If you want that event handlers have been processed in
reverse order, add postfix C<:r> to event name. When event handler is called,
arguments that have been specified in C<send_event> method are passed to it.
If in the last argument is passed the callback, the handler must be processed
in asynchronous mode using available event loop. If some error occurred in
asynchronous mode, the error message must be passed to the callback in the
first argument.

  App::Environ->register( __PACKAGE__,
    initialize => sub {
      my $cb   = pop if ref( $_[-1] ) eq 'CODE';
      my @args = @_;

      if ( defined $cb ) {
        # asynchronous handling...
      }
      else {
        # synchronous handling...
      }
    },
  );

=head2 send_event( $event [, @args ] [, $cb->( [ $err ] ) ] )

Sends specified event to App::Environ. All handlers registered for this event
will be processed. Arguments specified in C<send_event> method will be passed
to event handlers in the same order without modifications.

  App::Environ->send_event( 'initialize', qw( foo bar ) );

  App::Environ->send_event( 'initialize', qw( foo bar ),
    sub {
      my $err = shift;

      if ( defined $err ) {
        # error handling...

        return;
      }

      # success handling...
    }
  );

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
