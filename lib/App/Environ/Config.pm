package App::Environ::Config;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.16';

use App::Environ;
use Config::Processor;
use AnyEvent;
use Carp qw( croak );

my @REGISTERED_SECTIONS;
my %SECTIONS_IDX;
my $CONFIG;
my $NEED_CONFIG_INIT = 1;

App::Environ->register( __PACKAGE__,
  initialize   => sub { __PACKAGE__->_initialize(@_) },
  reload       => sub { __PACKAGE__->_reload(@_) },
  'finalize:r' => sub { __PACKAGE__->_finalize(@_) },
);


sub register {
  my $class = shift;
  my @config_sections = @_;

  foreach my $config_section (@config_sections) {
    next if exists $SECTIONS_IDX{$config_section};

    $SECTIONS_IDX{$config_section} = 1;
    push( @REGISTERED_SECTIONS, $config_section );

    $NEED_CONFIG_INIT = 1;
  }

  return;
}

sub instance {
  unless ( defined $CONFIG ) {
    croak __PACKAGE__ . ' must be initialized first';
  }

  return $CONFIG;
}

sub _initialize {
  my $class = shift;
  my $cb    = pop if ref( $_[-1] ) eq 'CODE';

  unless ($NEED_CONFIG_INIT) {
    if ( defined $cb ) {
      AE::postpone { $cb->() };
    }
    return;
  }

  eval {
    $class->_load;
  };
  if ($@) {
    my $err = $@;

    if ( defined $cb ) {
      chomp $err;
      AE::postpone { $cb->($err) };

      return;
    }

    die $err;
  }

  undef $NEED_CONFIG_INIT;

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _reload {
  my $class = shift;
  my $cb    = pop if ref( $_[-1] ) eq 'CODE';

  eval {
    $class->_load;
  };
  if ($@) {
    my $err = $@;

    if ( defined $cb ) {
      chomp $err;
      AE::postpone { $cb->($err) };

      return;
    }

    die $err;
  }

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _finalize {
  my $cb = pop if ref( $_[-1] ) eq 'CODE';

  undef $CONFIG;
  $NEED_CONFIG_INIT = 1;

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _load {
  my @config_dirs;
  if ( defined $ENV{APPCONF_DIRS} ) {
    @config_dirs = split /:/, $ENV{APPCONF_DIRS};
  }
  my $interpolate_vars   = $ENV{APPCONF_INTERPOLATE_VARIABLES};
  my $process_directives = $ENV{APPCONF_PROCESS_DIRECTIVES};

  my $config_processor = Config::Processor->new(
    dirs => \@config_dirs,
    $interpolate_vars ? ( interpolate_variables => $interpolate_vars ) : (),
    $process_directives ? ( process_directives => $process_directives ) : (),
  );

  $CONFIG = $config_processor->load(@REGISTERED_SECTIONS);

  return;
}

1;
__END__
=head1 NAME

App::Environ::Config - Configuration files processor for App::Environ

=head1 SYNOPSIS

  use App::Environ;
  use App::Environ::Config;

  App::Environ::Config->register( qw( foo.yml bar.json ) );

  App::Environ->send_event('initialize');

  my $config = App::Environ::Config->instance;

=head1 DESCRIPTION

App::Environ::Config is the configuration files processor for App::Environ.
Allows get access to configuraton tree from different application components.

The module registers in App::Environ three handlers for events C<initialize>,
C<reload> and C<finalize:r>.

=head1 METHODS

=head2 register( @config_sections )

The method registers configuration sections.

=head2 instance()

Gets reference to configuration tree.

=head1 SEE ALSO

L<App::Environ>, L<Config::Processor>

=head1 AUTHOR

Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016, Eugene Ponizovsky, E<lt>ponizovsky@gmail.comE<gt>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
