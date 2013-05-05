use strict;
use warnings;
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
        is $req->content => 'some_post_param=yes',
          'Successfully sent POST param';
        isnt $uri->query_param('some_query_param'), 'yes',
          'POST doesnt include param in uri';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'POST is working' } ) );
    }
);

$fake_ua->map(
    'http://some_alt_url/something',
    sub {
        my $req = shift;
        my $uri = $req->uri;

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { msg => 'non base response' } ) );
    }
);

$fake_ua->map(
    'http://localhost/failed_json_parse',
    sub {
        my $req = shift;
        return HTTP::Response->new( 200, 'OK', undef, 'THIS IS NOT JSON' );
    }
);

$fake_ua->map(
    'http://localhost/test/transform',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'POST', 'Method is POST';
        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { data => { result => [ 'item 1', 'item 2' ] } } ) );
    }
);
ok my $wj = WWW::JSON->new( ua => $fake_ua, base_url => 'http://localhost' );
ok my $get = $wj->get('/get/request');
ok $get->success, 'Got Success';
is $get->code => 200, 'Got 200 OK';
ok $get->res->{success} eq 'this is working';

ok my $get_404 = $wj->get('/404');
is $get_404->success => 0,   'Got no success';
is $get_404->code    => 404, 'Got code 404';

ok my $get_query_param =
  $wj->get( '/get/request', { some_query_param => 'yes' } );
ok $get_query_param->success, 'Got Success';
is $get_query_param->code => 200, 'Got 200';
ok $get_query_param->res->{success} eq 'this is also working';

ok my $post = $wj->post( '/post/request', { some_post_param => 'yes' } );
ok $post->success;
is $post->code => 200;
ok $post->res->{success} eq 'POST is working';

ok my $fail = $wj->post('/failed_json_parse');
ok $fail->http_response->is_success, 'HTTP request success';
is $fail->code    => 200, 'HTTP code 200';
is $fail->success => 0,   'JSON parse failed';
ok !defined( $fail->res ), 'No decoded json response';
is $fail->decoded_content => 'THIS IS NOT JSON';

ok my $req_non_base =
  $wj->post( 'http://some_alt_url/something', { param => 456 } );
ok $req_non_base->success, 'json success';
is $req_non_base->res->{msg} => 'non base response',
  'got back response from non base url';

ok my $transform =
  $wj->default_response_transform( sub { shift->{data}{result} } );
ok my $req_transform = $wj->post('/test/transform');
is_deeply $req_transform->res, [ 'item 1', 'item 2' ],
  'response_transform works';

ok $wj->clear_default_response_transform;
ok my $clear_transform = $wj->post('/test/transform');
is_deeply $clear_transform->res->{data}->{result}, [ 'item 1', 'item 2' ],
  'clear_response_transform works';

done_testing;
