package WWW::JSON::Role::Authorization;
use Moo::Role;
use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

has authorization_basic  => ( is => 'rw' );
has authorization_oauth1 => ( is => 'rw' );
has authorization_oauth2 => ( is => 'rw' );

around _make_request => sub {
    my ( $orig, $self ) = ( shift, shift );
    for my $auth (qw/authorization_basic authorization_oauth1 authorization_oauth2/) {
        my $handler = 'handle_' . $auth;
        $self->$handler(@_) if ( $self->$auth );
    }
    $self->$orig(@_);
};

sub handle_authorization_basic {
    my $self = shift;
    my $auth = $self->authorization_basic;
    $self->ua->default_headers->authorization_basic( $auth->{username},
        $auth->{password} );
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

sub handle_authorization_oauth2 {
    my ( $self, $method, $uri, $params ) = @_;
    my $token =
      ( $self->authorization_oauth2->can('access_token') )
      ? $self->authorization_oauth2->access_token
      : $self->authorization_oauth2;
    $self->ua->default_header( Authorization => 'Bearer '
          . $self->authorization_oauth2->access_token );
}

sub nonce {
    my @chars = ('A'..'Z','a'..'z','0'..'9');
    my $nonce = time;
    for (1 .. 15) {
        $nonce .= $chars[rand @chars];
    }
    return $nonce;
}

1;
