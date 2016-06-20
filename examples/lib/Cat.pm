package Cat;

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
    
    my $cat_config = App::Environ::Config->instance->{'cat'};

    print Dumper( $cat_config );
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

App::Environ::Config->register_config( qw( cat.json ) );

1;
