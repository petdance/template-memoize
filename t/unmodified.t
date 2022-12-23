#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use File::Slurp;
use Template::Test;


MAIN: {
    my %args = (
        POST_CHOMP => 1,
        TRIM => 1,
    );
    my $context = Template::Context::Memoize->new( \%args );

    my $test_cases = read_file( 't/basic.txt' );
    test_expect( $test_cases, { %args } );
}


exit 0;
