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
has json => ( is => 'ro', default => sub { JSON::XS->new } );
has response => ( is => 'ro', builder => '_build_response' );
has success => ( is => 'lazy', default => sub { 0 }, writer => '_set_success' );

sub _build_response {
    my $self = shift;
    return unless ( $self->http_response->is_success );

    return try {
        my $decoded =
          $self->json->decode( $self->http_response->decoded_content );
        $self->_set_success(1);
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
