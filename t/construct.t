#!/usr/bin/perl

use warnings;
use strict;
use 5.010;
use experimental 'signatures';

use Test::More tests => 3;

use Template;
use Template::Context::Memoize;


DEFAULT_CACHE: {
    my $context = Template::Context::Memoize->new();
    isa_ok( $context, 'Template::Context::Memoize' );
    isa_ok( $context->{cache}, 'CHI::Driver::File__WITH__CHI::Driver::Role::Universal' );

    my $template = Template->new({ CONTEXT => $context });
    isa_ok( $template, 'Template' );
}


exit 0;
