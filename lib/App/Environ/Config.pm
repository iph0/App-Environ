package App::Environ::Config;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.01_01';

use App::Environ;
use Config::Processor;
use Carp qw( croak );

my @REGISTERED_CONFIG_SECTIONS;
my %CONFIG_SECTIONS_IDX;
my $CONFIG;
my $RESOURCES_UPDATED = 0;

App::Environ->register( __PACKAGE__,
  initialize => sub {
    my $cb;
    if ( ref( $_[-1] ) eq 'CODE' ) {
      $cb = pop;
    }

    if ($RESOURCES_UPDATED) {
      my @config_dirs;
      if ( defined $ENV{APPCONF_DIRS} ) {
        @config_dirs = split /:/, $ENV{APPCONF_DIRS};
      }

      my $config_processor = Config::Processor->new(
        dirs                  => \@config_dirs,
        interpolate_variables => $ENV{APPCONF_INTERPOLATE_VARIABLES},
        process_directives    => $ENV{APPCONF_PROCESS_DIRECTIVES},
      );
      $CONFIG = $config_processor->load(@REGISTERED_CONFIG_SECTIONS);
    }

    if ( defined $cb ) {
      AE::postpone( sub { $cb->() } );
    }
  },

  finalize => sub {
    my $cb;
    if ( ref( $_[-1] ) eq 'CODE' ) {
      $cb = pop;
    }

    undef @REGISTERED_CONFIG_SECTIONS;
    undef %CONFIG_SECTIONS_IDX;
    undef $CONFIG;

    if ( defined $cb ) {
      AE::postpone( sub { $cb->() } );
    }
  },
);


sub register {
  my $self_class      = shift;
  my @config_sections = @_;

  foreach my $config_section (@config_sections) {
    next if $CONFIG_SECTIONS_IDX{$config_section};

    $CONFIG_SECTIONS_IDX{$config_section} = 1;
    push( @REGISTERED_CONFIG_SECTIONS, $config_section );
  }

  $RESOURCES_UPDATED = 1;

  return;
}

sub instance {
  unless ( defined $CONFIG ) {
    croak __PACKAGE__ . ' must be initialized first';
  }

  return $CONFIG;
}

1;
