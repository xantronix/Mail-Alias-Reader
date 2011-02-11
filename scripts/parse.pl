#! /usr/bin/perl -I../lib

use strict;
use warnings;

use Mail::Alias::Tiny;

my $aliases = Mail::Alias::Tiny->from_file($ARGV[0]);

foreach my $local_part (sort keys %{$aliases}) {
    my $destinations = $aliases->{$local_part};

    printf("%s: %s\n", $local_part, join(', ', map { $_->to_string } @{$destinations}));
}
