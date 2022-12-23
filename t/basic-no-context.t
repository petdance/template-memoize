#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use File::Slurp;
use Template::Test;

# Basic test NOT using the new context object. This is a baseline to compare against.

MAIN: {
    my %args = (
        POST_CHOMP => 1,
        TRIM => 1,
    );

    open( my $fh, '<', 't/basic.txt' ) or die;
    my $test_cases = join( '', <$fh> );
    close $fh;
    test_expect( $test_cases, { %args } );
}


exit 0;
