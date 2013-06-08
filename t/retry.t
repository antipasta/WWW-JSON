use strict;
use warnings;
use Test::More;
use Test::Mock::LWP::Dispatch;
use HTTP::Response;
use WWW::JSON;
use JSON;
use URI;
use URI::QueryParam;

my $json    = JSON->new;

ok my $wj = WWW::JSON->new( ua => $mock_ua, base_url => 'http://localhost' );

ok my $get_404 = $wj->get('/not_found');
isnt $get_404->success,   'Got no success';
is $get_404->code    => 404, 'Got code 404';

$mock_ua->map(
    'http://localhost/not_found',
    sub {
        my $req = shift;
        my $uri = $req->uri;
        is $req->method => 'GET', 'Method is GET';

        return HTTP::Response->new( 200, 'OK', undef,
            $json->encode( { success => 'this is also working' } ) );
    }
);

ok my $fixed = $get_404->retry;
ok $fixed->success,   'Got success';
is $fixed->code    => 200, 'Got code 200';
done_testing;
