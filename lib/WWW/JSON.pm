package WWW::JSON;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.04";
use Moo;
use Try::Tiny;
use URI;
use WWW::JSON::Response;
use Safe::Isa;
use JSON;
use HTTP::Request::Common;
use Data::Dumper::Concise;
use Module::Runtime qw( require_module );
has ua => (
    is      => 'lazy',
    handles => {
        timeout        => 'timeout',
        default_header => 'default_header',
        ua_request     => 'request'
    },
    builder => '_build_ua'
);
has base_url => (
    is     => 'rw',
    coerce => sub {
        my $base_url = shift;
        my $u;
        if ( ref($base_url) eq 'ARRAY' ) {
            my ( $url, $params ) = @{$base_url};
            $u = URI->new($url);
            $u->query_form(%$params);
        }
        else {
            $u = URI->new($base_url);
        }
        if ( my $path = $u->path ) {
            unless ( $path =~ m|/$| ) {
                $path =~ s|$|/|;
                $u->path($path);
            }
        }
        return $u;
    }
);
has body_params => ( is => 'rw', default => sub { +{} } );
has post_body_format => (
    is      => 'rw',
    default => sub { 'serialized' },
    clearer => 1,
    isa     => sub {
        die "Invalid post_body_format $_[0]"
          unless ( $_[0] eq 'serialized' || $_[0] eq 'JSON' );
    }
);
has json => ( is => 'ro', default => sub { JSON->new } );

has default_response_transform => (
    is      => 'rw',
    clearer => 1,
    isa     => sub {
        die "default_response_transform takes a coderef"
          unless ref( $_[0] ) eq 'CODE';
    }
);

has ua_options => ( is => 'lazy', default => sub { +{} } );
has ua_class   => ( is => 'lazy', default => sub { 'HTTP::Tiny' } );

with qw/WWW::JSON::Role::Authentication
  WWW::JSON::Role::HTTP::Tiny/;
my %METHOD_DISPATCH = (
    GET    => \&HTTP::Request::Common::GET,
    POST   => \&HTTP::Request::Common::POST,
    PUT    => \&HTTP::Request::Common::PUT,
    DELETE => \&HTTP::Request::Common::DELETE,
    HEAD   => \&HTTP::Request::Common::HEAD
);

sub get    { shift->req( 'GET',    @_ ) }
sub post   { shift->req( 'POST',   @_ ) }
sub put    { shift->req( 'PUT',    @_ ) }
sub delete { shift->req( 'DELETE', @_ ) }
sub head   { shift->req( 'HEAD',   @_ ) }

sub _build_ua {
    my $self  = shift;
    my $class = $self->ua_class;
    require_module($class) or die "$class not found";
    $class->new( %{ $self->ua_options } );
}

sub req {
    my ( $self, $method, $path, $params ) = @_;
    $params = {} unless defined($params);
    unless ( $path->$_isa('URI') ) {
        $path =~ s|^/|./|;
        $path = URI->new($path);
    }
    my $p =
      ( $method eq 'GET' )
      ? $params
      : { %{ $self->body_params }, %{$params} };
    my $abs_uri =
      ( $path->scheme ) ? $path : URI->new_abs( $path, $self->base_url );
    $abs_uri->query_form( $path->query_form, $self->base_url->query_form );

    return $self->_make_request( $method, $abs_uri, $p );
}

sub body_param {
    my ( $self, $k, $v ) = @_;
    $self->body_param->{$k} = $v;
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

sub _create_request_obj {
    my ( $self, $method, $uri, $p ) = @_;
    my $dispatch = $METHOD_DISPATCH{$method}
      or die "Method $method not implemented";

    my %payload;

    if ($p) {
        if ( $method eq 'GET' ) {
            $uri->query_form( $uri->query_form, %$p );
        }
        else { %payload = $self->_create_post_body($p) }
    }
    return $dispatch->( $uri->as_string, %payload );
}

sub _make_request {
    my ( $self, $method, $uri, $p ) = @_;
    my $request_obj = $self->_create_request_obj( $method, $uri, $p );
    my $resp = $self->ua_request($request_obj);

    return WWW::JSON::Response->new(
        {
            http_response       => $resp,
            _response_transform => $self->default_response_transform,
            json                => $self->json,
            _request_params     => [ $method, $uri, $p ],
            _parent             => $self,
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
        base_url => 'http://api.metacpan.org/v0?fields=name,distribution&size=1',
        post_body_format           => 'JSON',
        default_response_transform => sub { shift->{hits}{hits}[0]{fields} },
    );

    my $get = $wj->get(
        '/release/_search',
        {
            q      => 'author:ANTIPASTA',
            filter => 'status:latest',
        }
    );

    warn "DISTRIBUTION: " . $get->res->{distribution} if $get->success;

=head1 DESCRIPTION

WWW::JSON is an easy interface to any modern web API that returns JSON.

It tries to make working with these API's as intuitive as possible.

=head1 ABSTRACT

When using abstracted web API libraries I often ran into issues where bugs in the library interfere with proper api interactions, or features  are added to the API that the library doesn't support.

In these cases the additional abstraction winds up making life more difficult.

Abstracted libraries do offer benefits.

    -Auth is taken care of for you.
    -Cuts out boilerplate
    -Don't have to think about HTTP status, JSON, or parameter serialization

I wanted just enough abstraction to get the above benefits, but no more.

Thus, WWW::JSON was born. Perl + Web + JSON - tears

=head2 FEATURES

-Light on dependencies

-Don't repeat yourself

    -Set a url that all requests will be relative to
    -Set query params included on all requests
    -Set body params included on all requests that contain a POST body
    -Transform the response of all API requests. Useful if an API returns data in a silly structure.

-Work with APIs that require different parameter serialization

    - Serialized post bodys (Facebook, Foursquare)
    - JSON-ified post bodys (Github, Google+)

-Role-based Authentication

    -Basic
    -OAuth 1.0a
    -OAuth2
    -New roles can easily be created for other auth schemes

-Avoids boilerplate

    -Don't have to worry about going from JSON => perl and back
    -Handles HTTP and JSON decode errors gracefully



=head1 PARAMETERS

=head2 base_url

The root url that all requests will be relative to.

Any query parameters included in the base_url will be added to every request made to the api

Alternatively, an array ref consisting of the base_url and a hashref of query parameters can be passed like so:

base_url => [ 'http://google.com', { key1 => 'val1', key2 => 'val2'} ]

=head2 body_params

Parameters that will be added to every non-GET request made by WWW::JSON.

=head2 post_body_format

How to serialize the post body.

'serialized' - Normal post body serialization (this is the default)

'JSON' - JSONify the post body. Used by API's like github and google plus


=head2 default_response_transform

Many API's have a lot of boilerplate around their json responses.

For example lets say every request's meaningful payload is included inside the first array index of a hash key called 'data'.

Instead of having to do $res->{data}->[0]->{key1}, you can specify default_response_transform as sub { shift->{data}->[0] } 

Then in your responses you can get at key1 directly by just doing $res->{key1}

NOTE: This transform only occurs if no HTTP errors or decoding errors occurred. If we get back an HTTP error status it seems more useful to get back the entire decoded JSON blob

=head2 authentication

Accepts a single key value pair, where the key is the name of a WWW::JSON::Role::Authentication role and the value is a hashref containing the data the role needs to perform the authentication.

Supported authentication schemes:

OAuth1 => {
    consumer_key    => 'somekey',
    consumer_secret => 'somesecret',
    token           => 'sometoken',
    token_secret    => 'sometokensecret'
  }

Basic => { username => 'antipasta', password => 'hunter2' }

OAuth2 => Net::OAuth2::AccessToken->new( ... )

New roles can be created to support different types of authentication. Documentation on this will be fleshed out at a later time.

=head2 ua_options

Options that can be passed when initializing the useragent. For example { timeout => 5 }. See LWP::UserAgent for possibilities.

=head1 METHODS

=head2 get

$wj->get($path,$params)

Performs a GET request to the relative path $path. $params is a hashref of url query parameters.

=head2 post

$wj->post($path,$params)

Performs a POST request. $params is a hashref of parameters to be passed to the post body

=head2 put

$wj->put($path,$params)

Performs a PUT request. $params is a hashref of parameters to be passed to the post body


=head2 delete

$wj->delete($path,$params)

Performs a DELETE request. $params is a hashref of parameters to be passed to the post body

=head2 req

$wj->req($method,$path,$params)

Performs an HTTP request of type $method. $params is a hashref of parameters to be passed to the post body

=head2 body_param

Add/Update a single body param


=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=head1 SEE ALSO

-Net::OAuth2 - For making OAuth2 signed requests with WWW::JSON

-App::Adenosine - Using this on the command line definitely served as some inspiration for WWW::JSON.

-Net::HTTP::Spore - I found this while researching other modules in this space. It's still a bit abstracted from the actual web request for my taste, but it's obvious the author created it out of some of the same above frustrations and it looks useful.



=cut

