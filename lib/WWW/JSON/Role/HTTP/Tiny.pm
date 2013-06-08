package WWW::JSON::Role::HTTP::Tiny;
use HTTP::Tiny;
use Moo::Role;
use Safe::Isa;
use WWW::JSON::HTTPTinyResponse;

around 'ua_request' => sub {
    my ( $orig, $self ) = ( shift, shift );
    return $self->$orig(@_) unless ( $self->ua->$_isa('HTTP::Tiny') );
    my ($req) = @_;

    my %headers =
      map { $_ => $req->header($_) } $req->headers->header_field_names;
    my @params = (
        $req->method,
        $req->url,
        {
            content => $req->content,
            (%headers) ? ( headers => \%headers ) : ()
        }
    );
    return WWW::JSON::HTTPTinyResponse->new( %{ $self->$orig(@params) } );
};

1;
