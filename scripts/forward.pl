#! /usr/bin/perl -I../lib

use strict;
use warnings;

use Mail::Alias::Tiny;

my $reader = Mail::Alias::Tiny->open(
    'file' => $ARGV[0],
    'mode' => 'forward'
);

while (my $destinations = $reader->read) {
    print join(', ', map { $_->to_string } @{$destinations}) . "\n";
}
