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


=head1 CONSTRUCTOR

=head2 new( %args )

Arguments for the context.

If C<cache> is passed, then that's the cache object that will be used.

If C<cache_params> is passed, a new CHI cache object is created with those parms.

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

    return $self;
}


=head1 METHODS

=head2 process( $template, @args )

=head2 include( $template, @args )

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

    my $result;
    my $memoize_args = $params->{memoize};
    if ( defined $memoize_args ) {
        my $key = ref($template) ? $template->name : $template;
        $key = join(
            ':',
            (
                $key,
                map { "$_=" . ($memoize_args->{$_}//'') } sort keys %{$memoize_args}
            )
        );

        use Carp::Always;
        $result = $self->{cache}->get($key);
        if ( !defined($result) ) {
            if ( $action eq 'process' ) {
                $result = $self->SUPER::process( $template, $params, 0 );
            }
            else {
                $result = $self->SUPER::process( $template, $params, 'Localize me from Template::Context::Memoize' );
            }
            $self->{cache}->set( $key, $result ); # XXX Allow other args to set?
        }
    }
    else {
        if ( $action eq 'process' ) {
            $result = $self->SUPER::process( $template, $params, 0 );
        }
        else {
            $result = $self->SUPER::process( $template, $params, 'Localize me from Template::Context::Memoize' );
        }
    }


    return $result;
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
