#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use Template::Context::Memoize;

diag( "Testing Template::Context::Memoize $Template::Context::Memoize::VERSION, Perl $], $^X" );

pass( 'Module loaded' );

exit 0;
