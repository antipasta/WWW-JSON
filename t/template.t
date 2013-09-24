use strict;
use warnings;
use Test::More;
use Data::Dumper::Concise;

ok my $str = 'http://google.com/[%PAGE_ID%]/[% SOME_STRING  %]/hello';
diag $str;
my $replacements = { PAGE_ID => 123, foo => 'bar', SOME_STRING => 'yep' };
if ( $str =~ /\[\%/ ) {
    for my $key ( keys(%$replacements) ) {
        diag "KEY[$key]";
        my $val = $replacements->{$key};
        if ( $str =~ /\[\%\s*$key\s*\%\]/ ) {
            $str =~ s/\[\%\s*$key\s*\%\]/$val/g;
            delete $replacements->{$key};
        }
    }
}
is $str, 'http://google.com/123/yep/hello', 'replacement works';
diag $str;
diag Dumper($replacements);

done_testing;
