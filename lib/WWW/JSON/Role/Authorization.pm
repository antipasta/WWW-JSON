package WWW::JSON::Role::Authorization;
use Moo::Role;
use Net::OAuth;
use Safe::Isa;
use Data::Dumper::Concise;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

has authorization => (
    is      => 'rw',
    clearer => 1,
    default => sub { +{} },
    isa     => sub {
        die "Only 1 authorization method can be supplied "
          unless keys( %{$_[0]} ) <= 1;
    }
);

before clear_authorization => sub {
    my $self = shift;
    $self->ua->default_headers->remove_header('Authorization')
      if ( $self->authorization );
};

around _make_request => sub {
    my ( $orig, $self ) = ( shift, shift );
    if(my ($auth_type,$auth) = %{$self->authorization}){
        warn $auth_type . " " . Dumper($auth);
        my $handler = '_handle_' . $auth_type;
        die "No handler found for auth type [$auth_type]" unless ($self->can($handler));
        $self->$handler($auth,@_);
        my $res = $self->$orig(@_);
        $self->ua->default_headers->remove_header('Authorization');
        return $res;
    }
    return $self->$orig(@_);
};

sub _handle_basic {
    my ($self,$auth) = @_;
    $self->ua->default_headers->authorization_basic(
        @$auth{qw/username password/} );
}

sub _handle_oauth1 {
    my ( $self, $auth, $method, $uri, $params ) = @_;

    my $request = Net::OAuth->request("protected resource")->new(
        %$auth,
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
    my ( $self, $auth ) = shift;
    $self->ua->default_header(
        Authorization => 'Bearer ' . $auth->access_token );
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
