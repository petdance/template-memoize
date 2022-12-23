#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Template::Context::Memoize;

use Template qw( :status );
use Template::Test;

$Template::Test::DEBUG = 1;
$Template::Test::PRESERVE = 1;


MAIN: {
    my $context = Template::Context::Memoize->new;

    test_expect(\*DATA, {
        INTERPOLATE => 1,
        POST_CHOMP => 1,
        #        CONTEXT => $context,
    });
}


exit 0;


#------------------------------------------------------------------------
# test input
#------------------------------------------------------------------------

__DATA__
[% BLOCK cache_me %]
Hello
[% SET change_me = 'after' %]
[% END %]
[% SET change_me = 'before' %]
[% PROCESS cache_me %]
[% change_me %]
-- expect --
Hello
after
-- test --
[% BLOCK cache_me %]
Hello
[% SET change_me = 'after' %]
[% END %]
[% SET change_me = 'before' %]
[% INCLUDE cache_me %]
[% change_me %]
-- expect --
Hello
before
-- test --
[% BLOCK cache_me %]
 Hello [% name %]
[% END %]
[% SET name = 'Suzanne' %]
[% PROCESS cache_me name => name %]
[% SET name = 'World' %]
[% PROCESS cache_me name => name %]
-- expect --
 Hello Suzanne Hello World
