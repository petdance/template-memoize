package Template::Context::Memoize;

use warnings;
use strict;

=head1 NAME

Template::Context::Cacheable - profiling/caching-aware version of Template::Context

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

=head1 DESCRIPTION

Enables memoization of Template Toolkit templates.

=head2 Setup in Perl

    $Template::Config::CONTEXT = 'Template::Context::Memoize';

    # Then you can create a Template object like normal.
    my $template = Template->new( \%config );

=head2 Using in templates

Inside any template you can use cached subtemplates. See example:

    [% PROCESS subpage.tt memoize => { state => 'IL', zipcode => '60050' } %]

The C<memoize> argument gives the keys for the memoization. If no
C<memoize> argument is passed, then the template is PROCESSed like normal.

=cut

use parent 'Template::Context';
use CHI;
use Time::HiRes qw( time );


=head1 CONSTRUCTOR

=head2 new( %args )

Arguments for the context.

If C<cache> is passed, then that's the cache object that will be used.

If C<cache_params> is passed, a new CHI cache object is created with those parms.

If C<profiling> is passed and true, profiling stats will be shown after each include or process.

All other parms are passed to the parent constructor.

=cut

sub new {
    my $class   = shift;
    my $params  = shift // {};

    my $cache;
    if ( $params->{cache} ) {
        $cache = delete $params->{cache};
    }
    else {
        my $cache_params = delete $params->{cache_params};
        # If no cache parameters sent, supply some defaults.
        if ( !$cache_params ) {
            $cache_params = {
                driver             => 'File',
                root_dir           => '/tmp/cache',
                default_expires_in => 600, # 10 minutes
            };
        }
        # XXX Can the CHI constructor fail?
        $cache_params->{namespace} //= 'Memoize';
        $cache = CHI->new( %{$cache_params} );
    }

    my $self = $class->SUPER::new( $params );

    $self->{cache} = $cache;
    my $profiling = delete $params->{profiling};
    if ( defined $profiling ) {
        $self->{profiler_stack} = [];
        $self->{profiler_totals} = {};
        $self->{profiling} = $profiling;
    }

    return $self;
}


=head1 METHODS

=head2 process( $template [ , \%params ] )

Processes the C<$template> with the passed C<@args>. However, if one of the
C<%params> keys is "memoize", then memoization happens.

The key for the memoization cache is based on the template name and the key/value pairs in C<%params>.

In the template, it looks like this.

    [% PROCESS greeting memoize => {} %]

In this example, the cache key is simplys "greeting".

Setting the key/value pairs lets you specify the values you want to memoize
on.  In the example below, the cache key is "greeting:firstname=Fred:state=IL".

    [% PROCESS greeting memoize => { state => 'IL', firstname => 'Fred' } %]

These key/value pairs are passed in to the template as if you called:

    [% PROCESS greeting state => 'IL', firstname => 'Fred' %]

You can override the key/value pairs in the memoize argument by specifying
them outside of the memoize argument. For example:

    [% PROCESS greeting memoize => { state => 'IL', firstname => 'Fred' }, firstname => 'Barney' %]

would have a cache key with "firstname=Fred" but would pass "firstname=Barney" into the template.

=head2 include( $template, \%params )

Operates exactly like C<proces>, but localizes the variables first.

=head2 insert( $template )

There is no overridden insert method because it just pulls in a static file anyway.

=cut

sub include {
    my $self = shift;
    $self->_cached_action( 'include', @_ );
}


sub process {
    my $self = shift;
    $self->_cached_action( 'process', @_ );
}


sub _cached_action {
    my ( $self, $action, $template, $params ) = @_;

    my $template_name = ref($template) ? $template->name : $template;

    if ( $self->{profiling} ) {
        # Each stack entry has: [ inclusive start time, exclusive start time ]
        my $start_time = time;
        push @{$self->{profiler_stack}}, [$start_time, $start_time];
    }

    my $result;

    $params = { %{$params // {}} };
    my $memoize_kv = delete $params->{memoize};

    if ( defined $memoize_kv ) {
        my $key = join(
            ':',
            (
                $template_name,
                map { "$_=" . ($memoize_kv->{$_}//'') } sort keys %{$memoize_kv}
            )
        );
        $params = { %{$memoize_kv}, %{$params} };

        $result = $self->{cache}->get($key);
        if ( !defined($result) ) {
            if ( $action eq 'process' ) {
                $result = $self->SUPER::process( $template, $params, 0 );
            }
            elsif ( $action eq 'include' ) {
                $result = $self->SUPER::process( $template, $params, 'Localize me from Template::Context::Memoize' );
            }
            else {
                die "Invalid action $action";
            }
            $self->{cache}->set( $key, $result );
        }
    }
    else {
        if ( $action eq 'process' ) {
            $result = $self->SUPER::process( $template, $params, 0 );
        }
        elsif ( $action eq 'include' ) {
            $result = $self->SUPER::process( $template, $params, 'Localize me from Template::Context::Memoize' );
        }
        else {
            die "Invalid action $action";
        }
    }

    if ( $self->{profiling} ) {
        my $totals = $self->{profiler_totals};
        my $stack = $self->{profiler_stack};

        # Update counts now that the work is done.
        my $time = time;
        my $frame = pop @{$stack};

        # Totals counts are:
        # 0 - exclusive seconds
        # 1 - inclusive seconds
        # 2 - count of calls
        $totals->{$template_name}[0] += $time - $frame->[0];
        $totals->{$template_name}[1] += $time - $frame->[1];
        ++$totals->{$template_name}[2];
        for my $parent (@{$stack}) {
            $parent->[0] += $time - $frame->[0];
        }

        if ( !@{$stack} ) {
            $self->_dump_profiler_stack( $template_name );
        }
    }

    return $result;
}


sub _dump_profiler_stack {
    my $self = shift;
    my $template = shift;

    my $totals = $self->{profiler_totals};
    my $stack = $self->{profiler_stack};

    my $total_time = 0;
    print STDERR "-- $template at ". localtime, ":\n";
    for my $i ( sort { $totals->{$a}[1] cmp $totals->{$b}[1] } keys %{$totals} ) {
        my ($ex_secs, $in_secs, $count) = @{$totals->{$i}};
        printf STDERR "%3d %9.3f %9.3f %s\n", $count, $ex_secs * 1_000, $in_secs * 1_000, $i;
        $total_time += $ex_secs;
    }
    printf STDERR "%13.3f ms Total\n", $total_time * 1_000;
    print STDERR "-- end\n";
    $self->{profiler_stack} = [];

    return;
}


=head1 AUTHOR

Andy Lester, C<< andy@petdance.com >>

=head1 COPYRIGHT & LICENSE

Copyright 2022 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License v2.0.

See https://www.perlfoundation.org/artistic-license-20.html or the LICENSE.md
file that comes with the ack distribution.

=cut

1;
