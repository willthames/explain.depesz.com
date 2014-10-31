#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use English -no_match_vars;

use lib File::Spec->catfile( File::Spec->splitdir( dirname( __FILE__ ) ), 'lib' );

eval 'use Mojolicious::Commands';

die <<EOF if $EVAL_ERROR;
It looks like you do not have the Mojolicious Framework installed.
Please visit http://mojolicio.us for detailed installation instructions.

EOF

$ENV{ MOJO_APP } = 'Explain';

Mojolicious::Commands->start_app( 'Explain' );
