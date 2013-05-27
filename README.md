# NAME

WWW::JSON - Make working with JSON Web API's as painless as possible

# SYNOPSIS

    use WWW::JSON;
    

    my $wj = WWW::JSON->new(
        base_url    => 'https://graph.facebook.com',
        body_params => { access_token => 'XXXXX' }
    );
    my $r = $wj->get('/me', { fields => 'email' } );
    my $email = $r->res->{email} if ($r->success);

# DESCRIPTION

WWW::JSON is an easy interface to any modern web API that returns JSON.

It tries to make working with these API's as intuitive as possible.



# PARAMETERS

## base\_url

The root url that all requests will be relative to.

Any query parameters included in the base\_url will be added to every request made to the api

Alternatively, an array ref consisting of the base\_url and a hashref of query parameters can be passed like so:

base\_url => \[ 'http://google.com', { key1 => 'val1', key2 => 'val2'} \]

## body\_params

Parameters that will be added to every non-GET request made by WWW::JSON.

## default\_response\_transform

Many API's have a lot of boilerplate around their json responses.

For example lets say every request's meaningful payload is included inside the first array index of a hash key called 'data'.

Instead of having to do $res->{data}->\[0\]->{key1}, you can specify default\_response\_transform as sub { shift->{data}->\[0\] } 

Then in your responses you can get at key1 directly by just doing $res->{key1}

NOTE: This transform only occurs if no HTTP errors or decoding errors occurred. If we get back an HTTP error status it seems more useful to get back the entire decoded JSON blob



## authorization\_basic

Accepts a hashref of basic HTTP auth credentials in the format { username => 'antipasta', password => 'hunter2' }

Every request made by WWW::JSON will use these credentials.

## authorization\_oauth1

Accepts a hashref of OAuth 1.0A credentials. All requests made by WWW::JSON will use these credentias.



# METHODS

## get

$wj->get($path,$params)

Performs a GET request to the relative path $path. $params is a hashref of url query parameters.

## post

$wj->post($path,$params)

Performs a POST request. $params is a hashref of parameters to be passed to the post body

## put

$wj->put($path,$params)

Performs a PUT request. $params is a hashref of parameters to be passed to the post body

## req

$wj->req($method,$path,$params)

Performs an HTTP request of type $method. $params is a hashref of parameters to be passed to the post body

## body\_param

Add/Update a single body param



# LICENSE

Copyright (C) Joe Papperello.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Joe Papperello <antipasta@cpan.org>
