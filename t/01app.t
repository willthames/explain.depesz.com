use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Explain_Depesz_Com' }

ok( request('/')->is_success, 'Request should succeed' );
