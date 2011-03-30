#! /usr/bin/perl -I../lib

use strict;
use warnings;

use Mail::Alias::Reader;

my $reader = Mail::Alias::Reader->open(
    'file' => $ARGV[0],
    'mode' => 'aliases'
);

while (my ($name, $destinations) = $reader->read) {
    printf("%s: %s\n", $name, join(', ', map { $_->to_string } @{$destinations}));
}
