package WWW::JSON::Response;
use Moo;
use JSON::XS;

has http_response => (
    is       => 'ro',
    required => 1,
    handles  => [qw/is_success status_line decoded_content code/]
);
has json => ( is => 'ro', default => sub { JSON::XS->new } );
has response => ( is => 'lazy' );

sub _build_response {
    my $self = shift;
    return unless ( $self->is_success );
    return $self->json->decode( $self->decoded_content );
}

sub res {
    return shift->response;
}

1;
