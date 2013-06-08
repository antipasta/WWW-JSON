package WWW::JSON::HTTPTinyResponse;
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

WWW::JSON::HTTPTinyResponse - Basic class that wraps the response of HTTP::Tiny
with some basic accessors, used by WWW::JSON


=head1 LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Joe Papperello E<lt>antipasta@cpan.orgE<gt>

=cut

