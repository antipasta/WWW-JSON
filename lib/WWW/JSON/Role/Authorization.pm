package WWW::JSON::Role::Authorization;
use Moo::Role;
use Net::OAuth;
use Safe::Isa;
use Data::Dumper::Concise;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

has authorization => ( is => 'rw', clearer => 1 );

before 'clear_authorization' => sub {
    my $self = shift;
    $self->ua->default_headers->remove_header('Authorization')
      if ( $self->authorization );
  }

  around _make_request => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $auth = $self->authorization_type;
    warn $auth;
    if ($auth) {
        my $handler = '_handle_' . $auth;
        $self->$handler(@_);
    }
    my $res = $self->$orig(@_);
    $self->ua->default_headers->remove_header('Authorization') if ($auth);
    return $res;
  };

sub authorization_type {
    my $self = shift;
    return unless ( $self->authorization );
    return 'basic'
      if ( $self->authorization->{username} );
    return 'oauth1'
      if ( $self->authorization->{consumer_key} );
    return 'oauth2' if ( $self->authoriation->$_isa('Net::OAuth2') );
    die
"Cannot detect authorization type, invalid authorization parameters specified.";
}

sub _handle_basic {
    my $self = shift;
    $self->ua->default_headers->authorization_basic(
        @{ $self->authorization }{qw/username password/} );
}

sub _handle_oauth1 {
    my ( $self, $method, $uri, $params ) = @_;

    my $request = Net::OAuth->request("protected resource")->new(
        %{ $self->authorization },
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

sub _handle_oauth2 {
    my $self = shift;
    my $token =
      ( $self->authorization->can('access_token') )
      ? $self->authorization->access_token
      : $self->authorization;
    $self->ua->default_header(
        Authorization => 'Bearer ' . $self->authorization->access_token );
}

sub nonce {
    my @chars = ( 'A' .. 'Z', 'a' .. 'z', '0' .. '9' );
    my $nonce = time;
    for ( 1 .. 15 ) {
        $nonce .= $chars[ rand @chars ];
    }
    return $nonce;
}

1;
