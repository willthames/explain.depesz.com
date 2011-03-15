#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Mojo;

use_ok( 'Explain' );

my $t = Test::Mojo->new( app => 'Explain' );

$t->get_ok( '/' )->status_is( 200 );
