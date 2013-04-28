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
use Net::OAuth;
use Data::Dumper::Concise;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
has ua          => ( is => 'lazy' );
has base_url    => ( is => 'ro' );
has base_params => ( is => 'ro' );

has authorization_oauth1 => ( is => 'ro' );
has authorization_basic  => ( is => 'ro' );

sub _build_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    if ( my $auth = $self->authorization_basic ) {
        $ua->default_headers->authorization_basic( $auth->{username},
            $auth->{password} );
    }
    return $ua;
}

sub get {
    my ( $self, $path, $params ) = @_;
    $self->req( 'GET', $path, $params );
}

sub post {
    my ( $self, $path, $params ) = @_;
    $self->req( 'POST', $path, $params );
}

sub req {
    my ( $self, $method, $path, $params ) = @_;
    my $uri = URI->new( $self->base_url . $path );
    my %p = (%{ $self->base_params // {} }, %{ $params // {} });
    my $resp;

    $self->handle_authorization_oauth1( $method, $uri, \%p )
      if ( $self->authorization_oauth1 );

    my $lwp_method = lc($method);

    die "Method $lwp_method not implemented"
      unless ( $self->ua->can($lwp_method) );

    if ( $method eq 'GET' ) {
        $uri->query_form(%p);
        $resp = $self->ua->$lwp_method( $uri->as_string );
    }
    else {
        $resp = $self->ua->$lwp_method( $uri->as_string, \%p );
    }

    return WWW::JSON::Response->new( { http_response => $resp } );
}

sub handle_authorization_oauth1 {
    my ( $self, $method, $uri, $params ) = @_;

    my $request = Net::OAuth->request("protected resource")->new(
        %{ $self->authorization_oauth1 },
        request_url      => $uri->as_string,
        request_method   => $method,
        signature_method => 'HMAC-SHA1',
        timestamp        => time(),
        nonce            => nonce(),
        extra_params     => $params,
    );
    $request->sign;
    $request->to_authorization_header;
    $self->ua->default_header(
        Authorization => $request->to_authorization_header );
}

sub nonce {
    return 'changethislater' . time();
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

=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=cut

