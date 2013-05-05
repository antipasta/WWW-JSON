use Test::More;
use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use HTTP::Headers;
use WWW::JSON;
use JSON::XS;
use Data::Dumper::Concise;
use URI;
use URI::QueryParam;

my $json    = JSON::XS->new;
my $fake_ua = LWP::UserAgent->new;

$fake_ua->map(
    'http://localhost/get/request',
    sub {
        my $req = shift;
        is $req->method => 'GET', 'Method is GET';
        my $uri = $req->uri;

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/get/request?some_query_param=yes',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'GET', 'Method is GET';
        is $uri->query_param('some_query_param'), 'yes', 'Query param matches';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is also working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/post/request',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'POST', 'Method is POST';
        isnt $uri->query_param('some_query_param'), 'yes',
          'POST doesnt include param in uri';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'POST is working' } ) );
    }
);

$fake_ua->map(
    'http://localhost/failed_json_parse',
    sub {
        my $req = shift;
        return HTTP::Response->new( 200, 'OK', undef, 'THIS IS NOT JSON' );
    }
);

ok my $wj = WWW::JSON->new( ua => $fake_ua, base_url => 'http://localhost' );
ok my $req = $wj->get('/get/request');
ok $req->success, 'Got Success';
is $req->code => 200, 'Got 200 OK';
ok $req->res->{success} eq 'this is working';

ok my $req = $wj->get('/404');
is $req->success => 0,   'Got no success';
is $req->code    => 404, 'Got code 404';

ok my $req = $wj->get( '/get/request', { some_query_param => 'yes' } );
ok $req->success, 'Got Success';
is $req->code => 200, 'Got 200';
ok $req->res->{success} eq 'this is also working';

ok my $req = $wj->post( '/post/request',
    { some_post_param => 'yes', other_post_param => 'no' } );
ok $req->success;
is $req->code => 200;
ok $req->res->{success} eq 'POST is working';

ok my $req = $wj->post('/failed_json_parse');
ok $req->http_response->is_success, 'HTTP Request success';
is $req->code    => 200, 'HTTP code 200';
is $req->success => 0,   'JSON parse failed';
ok !defined( $req->res ), 'No decoded json response';
is $req->decoded_content => 'THIS IS NOT JSON';

done_testing;
