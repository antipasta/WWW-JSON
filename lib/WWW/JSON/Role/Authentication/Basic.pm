package WWW::JSON::Role::Authentication::Basic;
use Moo::Role;
requires 'authentication';
requires 'ua';

sub _auth_Basic {
    my ( $self, $auth ) = @_;
    $self->ua->default_headers->authorization_basic(
        @$auth{qw/username password/} );
}

1;
