#!/usr/bin/env perl

use 5.008000;
use strict;
use warnings;

use lib './examples/lib';

use FindBin;
use App::Environ
  initialize => 0,
  finalize   => 1;

BEGIN {
  $ENV{APPCONF_DIRS} = "$FindBin::Bin/etc";
}

use Cat;
use Dog;
use Cow;

use AnyEvent;

my $cv = AE::cv();

App::Environ->push_event( 'initialize', qw( foo bar ),
  sub {
    $cv->send();
  }
);

$cv->recv();

# Here doing something

$cv = AE::cv();

App::Environ->push_event( 'finalize',
  sub {
    $cv->send();
  }
);

$cv->recv();
