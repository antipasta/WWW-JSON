package WWW::JSON::HTTPResponse;
use strict;
use warnings;
use Moo;

has status_line     => ( is => 'ro', init_arg => 'reason' );
has base            => ( is => 'ro', init_arg => 'url' );
has is_success      => ( is => 'ro', init_arg => 'success' );
has decoded_content => ( is => 'ro', init_arg => 'content' );
has code            => ( is => 'ro' );


1;

__END__

=encoding utf-8

=head1 NAME

WWW::JSON::Response - Response objects returned by WWW::JSON requests

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

    if ($get->success) {
        say $r->res->{distribution};
    } else {
        say $r->error;
    }


=head1 DESCRIPTION

WWW::JSON::Response objects return data from WWW::JSON requests.

=head1 PARAMETERS

=head2 http_response

An HTTP::Response object containing json

=head1 METHODS

=head2 success

True if both the http request returned successfully (HTTP 200 OK) AND the json was successfully decoded. False if either of those things went horribly wrong.

=head2 error
If the http request failed then this is the contents of HTTP::Response->status_line. If the json parse failed it is a combination of the error encountered during JSON parse and the http status line

=head2 response

The results of decoding the json response. Will be decoded even in the event of an error, since hopefully the API is nice enough to return some json describing the error that occurred.

=head2 res

Alias for response

=head2 code

HTTP code returned by this request

=head2 status_line

HTTP status_line code returned by this request

=head2 content

The HTTP response's non json-decoded content

=head2 url

The url of this request

=head2 http_response

The HTTP::Response object corresponding to the request


=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=cut

