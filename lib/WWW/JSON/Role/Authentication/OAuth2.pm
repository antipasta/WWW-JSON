package WWW::JSON::Role::Authentication::OAuth2;
use Moo::Role;
requires 'authentication';
requires 'ua';

sub _auth_OAuth2 {
    my ( $self, $auth ) = @_;
    $self->ua->default_header(
        Authorization => 'Bearer ' . $auth->access_token );
}

1;
