#! /usr/bin/perl -I../lib

use strict;
use warnings;

use Mail::Alias::Parse;

my $aliases = Mail::Alias::Parse->read_file($ARGV[0]);

foreach my $name (keys %$aliases) {
    my @destinations = @{$aliases->{$name}};

    printf("%s: %s\n", $name, join(', ', map { $_->{'value'} } @destinations));
}
