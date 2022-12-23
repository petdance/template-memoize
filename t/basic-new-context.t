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

    open( my $fh, '<', 't/basic.txt' ) or die;
    my $test_cases = join( '', <$fh> );
    close $fh;
    test_expect( $test_cases, { CONTEXT => $context } );
}


exit 0;
