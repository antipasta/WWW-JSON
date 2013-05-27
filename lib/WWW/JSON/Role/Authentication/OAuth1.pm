package WWW::JSON::Role::Authentication::OAuth1;
use Moo::Role;
use Safe::Isa;
use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
requires 'authentication';
requires 'ua';

sub _handle_oauth1 {
    my ( $self, $auth, $method, $uri, $params ) = @_;

    my $request = Net::OAuth->request("protected resource")->new(
        %$auth,
        request_url      => $uri->as_string,
        request_method   => $method,
        signature_method => 'HMAC-SHA1',
        timestamp        => time(),
        nonce            => _nonce(),
        extra_params     => $params,
    );
    $request->sign;
    $request->to_authorization_header;
    $self->ua->default_header(
        Authorization => $request->to_authorization_header );
}

sub _nonce {
    my @chars = ( 'A' .. 'Z', 'a' .. 'z', '0' .. '9' );
    my $nonce = time;
    for ( 1 .. 15 ) {
        $nonce .= $chars[ rand @chars ];
    }
    return $nonce;
}
1;
