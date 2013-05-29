package WWW::JSON::Role::Authentication::Basic;
use Moo::Role;
requires 'authentication';
requires 'ua';


sub _validate_Basic {
    my ( $self, $auth ) = @_;
    for (qw/username password/) {
        die "Required parameter $_ missing for " . __PACKAGE__ . " authentication"
          unless exists( $auth->{$_} );
    }
}

sub _auth_Basic {
    my ( $self, $auth ) = @_;
    $self->ua->default_headers->authorization_basic(
        @$auth{qw/username password/} );
}

1;
