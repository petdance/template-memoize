#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Template::Context::Memoize;

use Template::Test;

# Basic test using the new context object but no memoization.

MAIN: {
    my %args = (
        POST_CHOMP => 1,
        TRIM => 1,
    );
    my $context = Template::Context::Memoize->new( \%args );

    test_expect( \*DATA, { CONTEXT => $context } );
}


exit 0;


__DATA__
-- test --
[% BLOCK greeting %]
Hello [% name %] at <TIME> on <DATE>
[% END %]
[% INCLUDE greeting memoize => { name => 'Jeana', '<TIME>' => 'wrong' } +%]
-- expect --
Hello Jeana at <TIME> on <DATE>
-- test --
[% BLOCK greeting %]
Hello [% name %] at <TIME> on <DATE>
[% END %]
[% INCLUDE greeting memoize => { name => 'Jeana' }, replace => { '<TIME>' => 'noon', '<DATE>' => 'Jun 25, 2022' }  +%]
-- expect --
Hello Jeana at noon on Jun 25, 2022
