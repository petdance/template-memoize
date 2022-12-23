#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Template::Context::Memoize;

use Template qw( :status );
use Template::Test;


MEMOIZE: {
    my %args = (
        POST_CHOMP => 1,
        TRIM => 1,
    );
    my $context = Template::Context::Memoize->new( \%args );

    my $test_cases = join( '', <DATA> );
    test_expect( $test_cases, { CONTEXT => $context } );
}


exit 0;

# XXX Tests to test
#
# Test that process only gets done once as noted by lack of side effects.

__DATA__
-- test --
[% BLOCK greeting %]
Hello included [% name %]
[% END %]
[% SET name = 'World' %]
[% INCLUDE greeting +%]
[% SET name = 'Universe' %]
[% INCLUDE greeting %]
-- expect --
Hello included World
Hello included Universe
-- test --
[% BLOCK greeting %]
Hello included inline [% name %]
[% END %]
[% INCLUDE greeting name = 'World' +%]
[% INCLUDE greeting name = 'Universe' %]
-- expect --
Hello included inline World
Hello included inline Universe
-- test --
[% BLOCK greeting %]
Hello processed [% name %]
[% END %]
[% SET name = 'World' %]
[% PROCESS greeting +%]
[% SET name = 'Universe' %]
[% PROCESS greeting %]
-- expect --
Hello processed World
Hello processed Universe
-- test --
[% BLOCK greeting %]
Hello processed inline [% name %]
[% END %]
[% PROCESS greeting name = 'World' +%]
[% PROCESS greeting name = 'Universe' %]
-- expect --
Hello processed inline World
Hello processed inline Universe
