package WWW::JSON;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";
use LWP::UserAgent;
use Moo;
use Try::Tiny;
use URI;
use WWW::JSON::Response;
use Data::Dumper::Concise;
use Safe::Isa;
use JSON::XS;

has ua => (
    is      => 'lazy',
    handles => [qw/default_header default_headers timeout/],
    default => sub { LWP::UserAgent->new }
);
has base_url => (
    is     => 'rw',
    coerce => sub {
        my $base_url = shift;
        return $base_url if ( $base_url->$_isa('URI') );
        if ( ref($base_url) eq 'ARRAY' ) {
            my ( $url, $params ) = @{$base_url};
            my $u = URI->new($url);
            $u->query_form(%$params);
            return $u;
        }
        return URI->new($base_url);
    }
);
has base_params => ( is => 'rw', default => sub { +{} } );
has post_body_format =>
  ( is => 'rw', default => sub { 'serialized' }, clearer => 1 );
has json => ( is => 'ro', default => sub { JSON::XS->new } );

has default_response_transform => (
    is      => 'rw',
    clearer => 1,
    isa     => sub {
        die "default_response_transform takes a coderef"
          unless ref( $_[0] ) eq 'CODE';
    }
);
with 'WWW::JSON::Role::Authorization';

sub get  { shift->req( 'GET',  @_ ) }
sub post { shift->req( 'POST', @_ ) }

sub req {
    my ( $self, $method, $path, $params ) = @_;
    unless ( $path->$_isa('URI') ) {
        $path =~ s|^/|./|;
        $path = URI->new($path);
    }

    my $abs_uri =
      ( $path->scheme ) ? $path : URI->new_abs( $path, $self->base_url );
    $abs_uri->query_form( $path->query_form, $self->base_url->query_form );
    my $p = { %{ $self->base_params }, %{ $params // {} } };

    return $self->_make_request( $method, $abs_uri, $p );
}

sub base_param {
    my ( $self, $k, $v ) = @_;
    $self->base_params->{$k} = $v;
}

sub _create_post_body {
    my ( $self, $p ) = @_;
    if ( $self->post_body_format eq 'JSON' ) {
        return (
            'Content-Type' => 'application/json',
            Content        => $self->json->encode($p)
        );
    }
    return ( Content => $p );
}

sub _make_request {
    my ( $self, $method, $uri, $p ) = @_;

    my $lwp_method = lc($method);
    die "Method $method not implemented" unless ( $self->ua->can($lwp_method) );
    my %payload;

    if ($p) {
        if ( $method eq 'GET' ) {
            $uri->query_form( $uri->query_form, %$p );
        }
        else { %payload = $self->_create_post_body($p) }
    }
    my $resp = $self->ua->$lwp_method( $uri->as_string, %payload );

    return WWW::JSON::Response->new(
        {
            http_response      => $resp,
            response_transform => $self->default_response_transform
        }
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::JSON - Make working with JSON Web API's as painless as possible

=head1 SYNOPSIS

    use WWW::JSON;
    
    my $wj = WWW::JSON->new(
        base_url    => 'https://graph.facebook.com',
        base_params => { access_token => 'XXXXX' }
    );
    my $r = $wj->get('/me', { fields => 'email' } );
    my $email = $r->res->{email} if ($r->success);

=head1 DESCRIPTION

WWW::JSON is an easy interface to any modern web API that returns JSON.

It tries to make working with these API's as intuitive as possible.


=head1 PARAMETERS

=head2 base_url

The root url that all requests will be relative to.

=head2 base_params

Parameters that will be added to every request made by WWW::JSON. Useful for basic api keys

=head2 default_response_transform

Many API's have a lot of boilerplate around their json responses.

For example lets say every request's meaningful payload is included inside the first array index of a hash key called 'data'.

Instead of having to do $res->{data}->[0]->{key1}, you can specify default_response_transform as sub { shift->{data}->[0] } 

Then in your responses you can get at key1 directly by just doing $res->{key1}

NOTE: This transform only occurs if no HTTP errors or decoding errors occurred. If we get back an HTTP error status it seems more useful to get back the entire decoded JSON blob


=head2 authorization_basic

Accepts a hashref of basic HTTP auth credentials in the format { username => 'antipasta', password => 'hunter2' }

Every request made by WWW::JSON will use these credentials.

=head2 authorization_oauth1

Accepts a hashref of OAuth 1.0A credentials. All requests made by WWW::JSON will use these credentias.


=head1 METHODS

=head2 get

$wj->get($path,$params)

Performs a GET request to the relative path $path. $params is a hashref of url query parameters.

=head2 post

$wj->post($path,$params)

Performs a POST request. $params is a hashref of parameters to be passed to the post body

=head2 req

$wj->req($method,$path,$params)

Performs an HTTP request of type $method. $params is a hashref of parameters to be passed to the post body

=head2 default_header

Set a default header for your requests

=head2 base_param

Add/Update a single base param


=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=cut

