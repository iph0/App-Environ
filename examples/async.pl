#!/usr/bin/env perl

use 5.008000;
use strict;
use warnings;

use lib './examples/lib';

use FindBin;
use App::Environ;

BEGIN {
  $ENV{APPCONF_DIRS} = "$FindBin::Bin/etc";
}

use Cat;
use Dog;
use Cow;

use AnyEvent;

my $cv = AE::cv;
App::Environ->push_event( 'initialize', qw( foo bar ), sub { $cv->send } );
$cv->recv;

$cv = AE::cv;
App::Environ->push_event( 'reload', sub { $cv->send } );
$cv->recv;

$cv = AE::cv;
App::Environ->push_event( 'finalize-r', sub { $cv->send } );
$cv->recv;
