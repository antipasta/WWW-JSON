package WWW::JSON;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";
use JSON::XS;
use LWP::UserAgent;
use Moo;
use Try::Tiny;
use URI;
use WWW::JSON::Response;
use Net::OAuth;
use Data::Dumper::Concise;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
has ua   => ( is => 'ro', default => sub { LWP::UserAgent->new } );
has json => ( is => 'ro', default => sub { JSON::XS->new } );
has base_url    => ( is => 'ro' );
has base_params => ( is => 'ro' );

has authorization_oauth1 => ( is => 'ro' );
has authorization_basic  => ( is => 'ro' );

sub get {
    my ( $self, $path, $params ) = @_;
    $self->req( 'get', $path, $params );
}

sub post {
    my ( $self, $path, $params ) = @_;
    $self->req( 'post', $path, $params );
}

sub req {
    my ( $self, $method, $path, $params ) = @_;
    my $uri = URI->new( $self->base_url . $path );
    my %params = ( %{ $self->base_params // {} }, %{ $params // {} } );
    my ( $resp, $json );
    if ( $self->authorization_oauth1 ) {
        my $request = Net::OAuth->request("protected resource")->new(
            %{ $self->authorization_oauth1 },
            request_url      => $uri->as_string,
            request_method   => uc($method),
            signature_method => 'HMAC-SHA1',
            timestamp        => time(),
            nonce            => nonce(),
            extra_params     => \%params,
        );
        $request->sign;
        $request->to_authorization_header;
        $self->ua->default_header(
            Authorization => $request->to_authorization_header );
    }
    if ( my $auth = $self->authorization_basic ) {
        $self->ua->authorization_basic( $auth->{username}, $auth->{password} );
    }

    if ( $method eq 'get' ) {
        $uri->query_form(%params);
        $resp = $self->ua->$method( $uri->as_string );
    }
    else {
        $resp = $self->ua->$method( $uri->as_string, \%params );
    }
    return WWW::JSON::Response->new( { http_response => $resp } );
}

sub nonce {
    return 'changethislater' . time();
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::JSON - A simple way to interact with JSON web API's

=head1 SYNOPSIS

    use WWW::JSON;

=head1 DESCRIPTION

WWW::JSON is ...

=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=cut

