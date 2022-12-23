#!/usr/bin/perl

use warnings;
use strict;
use 5.010;
use experimental 'signatures';

use Test::More tests => 2;

use Template;
use Template::Context::Memoize;

$Template::Config::CONTEXT = 'Template::Context::Memoize';

MAIN: {
    my $template = Template->new();
    isa_ok( $template, 'Template' );

    isa_ok( $template->context, 'Template::Context::Memoize' );
}


exit 0;
