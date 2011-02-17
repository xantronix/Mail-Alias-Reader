use strict;
use warnings;

use Test::More ('no_plan');

use Mail::Alias::Tiny::Token;

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

    '"/home/foo/Documents/Mail Spools/foo"' => {
        'is_value'     => 1,
        'is_punct'     => 0,
        'is_address'   => 0,
        'is_directive' => 0,
        'is_command'   => 0,
        'is_file'      => 1,
        'to_value'     => '/home/foo/Documents/Mail Spools/foo',
        'to_string'    => '"/home/foo/Documents/Mail Spools/foo"'
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
