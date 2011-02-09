package Mail::Alias::Tiny;

use strict;
use warnings;

use Mail::Alias::Tiny::Parser;

sub read {
    my ($class, $fh, $local_part, $destinations) = @_;

    while (my $line = readline($fh)) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next unless $line;
        next if $line =~ /^(#|$)/;

        ($local_part, $destinations) = Mail::Alias::Tiny::Parser->parse($line);

        return 1;
    }

    return 0;
}

sub from_file {
    my ($class, $file) = @_;
    my %ret;

    open(my $fh, '<', $file) or die("Unable to open mail aliases file $file for reading");

    while ($class->read($fh, my ($local_part, $destinations))) {
        $ret{$local_part} = $destinations;
    }

    close($fh);

    return \%ret;
}

1;
