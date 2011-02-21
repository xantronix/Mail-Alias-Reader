use strict;
use warnings;

use Test::More ('no_plan');

use Mail::Alias::Tiny::Token ('tests' => 69);

my %TESTS = (
    '#foo' => {
        'is_value'     => 0,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_value'     => 'foo',
        'to_string'    => '# foo'
    },

    '"/Mail Spools/foo\0173bar\0175/Test \x2b 123"' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 1,
        'to_value'     => '/Mail Spools/foo{bar}/Test + 123',
        'to_string'    => '"/Mail Spools/foo\0173bar\0175/Test \x2b 123"'
    },

    ',' => {
        'is_value'     => 0,
        'is_punct'     => 1,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ','
    },

    ':' => {
        'is_value'     => 0,
        'is_punct'     => 1,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ':'
    },

    '   ' => {
        'is_value'     => 0,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ' '
    },

    ':test:/value' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 1,
        'is_command'   => 0,
        'is_file'      => 0,
        'to_string'    => ':test:/value',
        'to_value'     => '/value'
    },

    '/foo/bar/baz' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 1,
        'to_string'    => '/foo/bar/baz',
        'to_value'     => '/foo/bar/baz'
    },

    '|foo' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 1,
        'is_file'      => 0,
        'to_string'    => '|foo',
        'to_value'     => 'foo'
    },

    '"|append \"\r\n\t\""' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 1,
        'is_file'      => 0,
        'to_string'    => '"|append \"\r\n\t\""',
        'to_value'     => qq(|append "\r\n\t")
    }
);

foreach my $test (keys %TESTS) {
    my $checks = $TESTS{$test};
    my $token = Mail::Alias::Tiny::Token->tokenize($test)->[1];

    foreach my $method (keys %{$checks}) {
        my $expected = $checks->{$method};
        
        ok($token->$method() eq $expected, qq(Mail::Alias::Tiny::Token->$method() for "$test" is $expected));
    }
}
