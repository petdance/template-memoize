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

# XXX Tests to test
#
# Test that process only gets done once as noted by lack of side effects.

__DATA__
-- test --
[% BLOCK greeting %]
Hello [% name %]
[% END %]
[% SET name = 'World' %]
[% PROCESS greeting +%]
[% SET name = 'Universe' %]
[% PROCESS greeting %]
-- expect --
Hello World
Hello Universe
