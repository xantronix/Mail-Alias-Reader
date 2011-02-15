#! /usr/bin/perl -I../lib

use strict;
use warnings;

use Mail::Alias::Tiny;

my $reader = Mail::Alias::Tiny->open(
    'file' => $ARGV[0],
    'mode' => 'aliases'
);

while (my ($name, $destinations) = $reader->read) {
    printf("%s: %s\n", $name, join(', ', map { $_->to_string } @{$destinations}));
}
