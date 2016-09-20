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

App::Environ->push_event( 'initialize', qw( foo bar ) );

App::Environ->push_event('reload');

App::Environ->push_event('finalize:r');
