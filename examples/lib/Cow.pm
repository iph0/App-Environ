package Cow;

use strict;
use warnings;

use App::Environ;
use App::Environ::Config;
use AnyEvent;
use Data::Dumper;

App::Environ->register( __PACKAGE__,
  initialize => sub {
    my $cb;
    if ( ref( $_[-1] ) eq 'CODE' ) {
      $cb = pop;
    }

    my $cow_config = App::Environ::Config->instance->{'cow'};

    print Dumper( $cow_config );
    print __PACKAGE__ . " initialized\n";

    if ( defined $cb ) {
      AE::postpone( sub { $cb->() } );
    }
  },

  finalize => sub {
    my $cb;
    if ( ref( $_[-1] ) eq 'CODE' ) {
      $cb = pop;
    }

    print __PACKAGE__ . " finalized\n";

    if ( defined $cb ) {
      AE::postpone( sub { $cb->() } );
    }
  },
);

App::Environ::Config->register_config( qw( cow.yml ) );

1;
