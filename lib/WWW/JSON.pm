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
has ua => (
    is      => 'lazy',
    handles => [qw/default_header default_headers/],
    default => sub { LWP::UserAgent->new }
);
has base_url    => ( is => 'rw' );
has base_params => ( is => 'rw' );

has default_response_transform => ( is => 'rw' );
with 'WWW::JSON::Role::Authorization';


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
    my $abs_uri = URI->new( $self->base_url . $path );
    my %p = ( %{ $self->base_params // {} }, %{ $params // {} } );

    return $self->_make_request($method,$abs_uri,\%p);
}

sub _make_request {
    my ($self,$method,$uri,$p) = @_;
    my $lwp_method = lc($method);
    my $resp;

    die "Method $lwp_method not implemented"
      unless ( $self->ua->can($lwp_method) );

    if ( $method eq 'GET' ) {
        $uri->query_form(%$p);
        $resp = $self->ua->$lwp_method( $uri->as_string );
    }
    else {
        $resp = $self->ua->$lwp_method( $uri->as_string, $p );
    }

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


=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=cut

