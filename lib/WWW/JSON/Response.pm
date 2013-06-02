package WWW::JSON::Response;
use Moo;
use JSON::XS;
use Try::Tiny;

has http_response => (
    is       => 'ro',
    required => 1,
    handles  => [qw/status_line decoded_content code/],
);
has json => ( is => 'lazy', default => sub { JSON::XS->new } );
has success => ( is => 'lazy', writer => '_set_success' );
has _response_transform => ( is => 'ro' );
has response => ( is => 'lazy', builder => '_build_response' );

sub _build_success {
    my $self = shift;
    $self->_set_success(0);
    $self->response;
    return $self->success;
}

sub _build_response {
    my $self = shift;
    return try {
        my $decoded =
          $self->json->decode( $self->http_response->decoded_content );
        if ( $self->http_response->is_success ) {
            $decoded = $self->_response_transform->($decoded,$self)
              if ( defined( $self->_response_transform ) );
            $self->_set_success(1);
        }
        return $decoded;
    }
    catch {
        warn "Error decoding json [$_]";
        return;
    };
}

sub res { shift->response }

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
    if ($r->success) {
        print $r->res->{email} . "\n";
    } else {
        print "HTTP ERROR CODE " . $r->code . "\n";
        print "HTTP STATUS " . $r->status_line . "\n";
    }


=head1 DESCRIPTION

WWW::JSON::Response objects return data from WWW::JSON requests.

=head1 PARAMETERS

=head2 http_response

An HTTP::Response object containing json

=head1 METHODS

=head2 success

1 if both the http request returned successfully (HTTP 200 OK) AND the json was successfully decoded. 0 if either of those things went badly.

=head2 response

The results of decoding the json response. Will be decoded even in the event of an error, since hopefully the API is nice enough to return some json describing the error that occurred.

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

