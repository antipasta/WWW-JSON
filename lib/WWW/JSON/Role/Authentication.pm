package WWW::JSON::Role::Authentication;
use Moo::Role;
has authentication => (
    is      => 'rw',
    clearer => 1,
    default => sub { +{} },
    isa     => sub {
        return if ref( $_[0] ) eq 'CODE';
        die "Only 1 authentication method can be supplied "
          unless keys( %{ $_[0] } ) <= 1;
    }
);

before clear_authentication => sub {
    my $self = shift;
    $self->ua->default_headers->remove_header('Authorization')
      if ( $self->authentication );
};

around _make_request => sub {
    my ( $orig, $self ) = ( shift, shift );
    if ( ref( $self->authentication ) eq 'CODE' ) {
        $self->authentication->( $self, @_ );
    }
    elsif ( my ( $auth_type, $auth ) = %{ $self->authentication } ) {
        my $role = __PACKAGE__ . '::' . $auth_type;
        Moo::Role->apply_roles_to_object( $self, $role )
          unless $self->does($role);
        my $handler = '_auth_' . $auth_type;
        die "No handler found for auth type [$auth_type]"
          unless ( $self->can($handler) );
        $self->$handler( $auth, @_ );
        my $res = $self->$orig(@_);
        $self->ua->default_headers->remove_header('Authorization');
        return $res;
    }
    return $self->$orig(@_);
};

with qw/WWW::JSON::Role::Authentication::Basic
  WWW::JSON::Role::Authentication::OAuth1
  WWW::JSON::Role::Authentication::OAuth2/;
1;
