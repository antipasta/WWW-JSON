package WWW::JSON::Response;
use Moo;
use JSON::XS;
use Try::Tiny;
use Data::Dumper::Concise;

has http_response => (
    is       => 'ro',
    required => 1,
    handles  => [qw/status_line decoded_content code/],
);
has json => ( is => 'lazy', default => sub { JSON::XS->new } );
has success => ( is => 'lazy', default => sub { 0 }, writer => '_set_success' );
has response_transform => ( is => 'ro' );
has response => ( is => 'lazy', builder => '_build_response' );

## success requires that response has been built
before 'success' => sub { my $self = shift; $self->response; };

sub _build_response {
    my $self = shift;

    return try {
        my $decoded =
          $self->json->decode( $self->http_response->decoded_content );
        $decoded = $self->response_transform->($decoded)
          if ( defined( $self->response_transform ) );
        $self->_set_success(1) if ( $self->http_response->is_success );
        return $decoded;
    }
    catch {
        warn "Error decoding json [$_]";
        return;
    };
}

sub res {
    return shift->response;
}

1;

__END__

=encoding utf-8

=head1 NAME

WWW::JSON::Response - Response objects returned by WWW::JSON requests

=head1 SYNOPSIS

    use WWW::JSON;
    
    my $wj = WWW::JSON->new(
        base_url    => 'https://graph.facebook.com',
        base_params => { access_token => 'XXXXX' }
    );
    my $r = $wj->get('/me', { fields => 'email' } );
    my $email = $r->res->{email} if ($r->success);

=head1 DESCRIPTION

WWW::JSON::Response objects return data from WWW::JSON requests.

=head1 PARAMETERS

=head2 http_response

An HTTP::Response object containing json

=head1 METHODS

=head2 success

1 if both the http request returned successfully (HTTP 200 OK) AND the json was successfully decoded. 0 if either of those things went badly.

=head2 response

If the request returned successfully, contains the result of decoding the request's json

=head2 res

Alias for response

=head2 code

HTTP code returned by this request

=head2 status_line

HTTP status_line code returned by this request

=head2 decoded_content

The HTTP response's non json-decoded content

=head2 http_response

The HTTP::Response object corresponding to the request


=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=cut

