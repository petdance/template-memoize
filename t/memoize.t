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
Hello included [% name %]
[% END %]
[% SET name = 'World' %]
[% INCLUDE greeting memoize => {} +%]
[% SET name = 'Everybody else' %]
[% INCLUDE greeting memoize => {} %]
-- expect --
Hello included World
Hello included World
-- test --
[% BLOCK greeting %]
Hello memoized args [% name %] and [% other %]
[% END %]
[% INCLUDE greeting memoize => { name => 'World' } other='dingo' +%]
[% INCLUDE greeting memoize => { name => 'World' } other='Some other "other" value' +%]
-- expect --
Hello memoized args World and dingo
Hello memoized args World and dingo
-- test --
[% BLOCK greeting %]
Hello memoized override arg [% name %]
[% END %]
[% INCLUDE greeting memoize => { name => 'Bud' } name => 'Lou' +%]
[% INCLUDE greeting memoize => { name => 'Bud' } name => 'No longer Lou' +%]
-- expect --
Hello memoized override arg Lou
Hello memoized override arg Lou
