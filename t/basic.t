#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Mojo;

use_ok( 'Explain' );
use_ok( 'Date::Simple' );
use_ok( 'Mail::Sender' );
use_ok( 'Pg::Explain' );
use_ok( 'Email::Valid' );

my $t = Test::Mojo->new( 'Explain' );

$t->get_ok( '/' )->status_is( 200 );
