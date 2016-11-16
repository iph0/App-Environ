package App::Environ::Config;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.01_01';

use App::Environ;
use Config::Processor;
use AnyEvent;
use Carp qw( croak );

my @REGISTERED_SECTIONS;
my $CONFIG;
my %SECTIONS_IDX;
my $NEED_INIT = 0;


App::Environ->register( __PACKAGE__,
  initialize   => sub { __PACKAGE__->_initialize(@_) },
  reload       => sub { __PACKAGE__->_reload(@_) },
  'finalize:r' => sub { __PACKAGE__->_finalize(@_) },
);


sub register {
  my $class = shift;
  my @config_sections = @_;

  foreach my $config_section (@config_sections) {
    next if $SECTIONS_IDX{$config_section};
    $SECTIONS_IDX{$config_section} = 1;
    push( @REGISTERED_SECTIONS, $config_section );
  }

  $NEED_INIT = 1;

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
  my $cb = pop if ref( $_[-1] ) eq 'CODE';

  if ($NEED_INIT) {
    $class->_load_config;
    $NEED_INIT = 0;
  }

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _reload {
  my $class = shift;
  my $cb = pop if ref( $_[-1] ) eq 'CODE';

  $class->_load_config;

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _finalize {
  my $cb = pop if ref( $_[-1] ) eq 'CODE';

  undef @REGISTERED_SECTIONS;
  undef %SECTIONS_IDX;
  undef $CONFIG;

  if ( defined $cb ) {
    AE::postpone { $cb->() };
  }

  return;
}

sub _load_config {
  my @config_dirs;
  if ( defined $ENV{APPCONF_DIRS} ) {
    @config_dirs = split /:/, $ENV{APPCONF_DIRS};
  }

  my $config_processor = Config::Processor->new(
    dirs                  => \@config_dirs,
    interpolate_variables => $ENV{APPCONF_INTERPOLATE_VARIABLES},
    process_directives    => $ENV{APPCONF_PROCESS_DIRECTIVES},
  );

  $CONFIG = $config_processor->load(@REGISTERED_SECTIONS);

  return;
}

1;
__END__
=head1 NAME

App::Environ::Config - Configuration files processor for App::Environ

=head1 SYNOPSIS

  use App::Environ::Config;

  App::Environ::Config->register( qw( foo.yml bar.json ) );

  my $config = App::Environ::Config->instance;

=head1 DESCRIPTION

App::Environ::Config is the configuration files processor for App::Environ.
Allows get access to configuraton tree from different application components.

=head1 METHODS

=head2 register( @config_sections )

Registers configuration sections.

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
