use 5.008000;
use strict;
use warnings;

use Test::More tests => 1;

my $T_CLASS;

BEGIN {
  $T_CLASS = 'App::Environ';
  use_ok( $T_CLASS );
};

can_ok( $T_CLASS, 'register' );
can_ok( $T_CLASS, 'push_event' );
