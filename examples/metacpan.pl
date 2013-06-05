#!/usr/bin/env perl
use WWW::JSON;
use Data::Dumper;

# /v0/release/_search?q=author:MSTROUT&filter=status:latest&fields=name&size=5
my $wj = WWW::JSON->new(
    base_url => 'http://api.metacpan.org/v0?fields=name,distribution&size=1',
    post_body_format           => 'JSON',
    default_response_transform => sub { shift->{hits}{hits}[0]{fields} },
);

my $get = $wj->get(
    '/release/_search',
    {
        q      => 'author:ANTIPASTA',
        filter => 'status:latest',
    }
);

warn "DISTRIBUTION: " . $get->res->{distribution} if $get->success;

warn "Status is " . $get->status_line;
warn "Request URL is " . $get->url;
warn "Content is " . Dumper( $get->res );

my $post = $wj->post(
    '/release/_search',
    {

        filter => {
            term => {
                'release.dependency.module' => 'Moo',
            }
        },
        size => 1
    }
);
warn "Status is " . $post->status_line;
warn "Request URL is " . $post->url;
warn "Content is " . Dumper( $post->res );
