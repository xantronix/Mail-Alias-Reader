package Mail::Alias::Tiny;

use strict;
use warnings;

use Mail::Alias::Tiny::Parser ();

=head1 NAME

Mail::Alias::Tiny

=head1 DESCRIPTION

A small package for reading aliases(5) declarations

=head1 SYNOPSIS

    use Mail::Alias::Tiny ();

    open(my $fh, '<', '/etc/aliases') or die("Cannot open /etc/aliases: $!");

    while (my ($local_part, $destinations) = Mail::Alias::Tiny->read($fh)) {

    }

=head1 ABOUT

=cut

sub read {
    my ($class, $fh) = @_;

    while (my $line = readline($fh)) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next unless $line;
        next if $line =~ /^(#|$)/;

        return Mail::Alias::Tiny::Parser->parse($line);
    }

    return;
}

sub from_file {
    my ($class, $file) = @_;
    my %ret;

    open(my $fh, '<', $file) or die("Unable to open mail aliases file $file for reading");

    while (my ($local_part, $destinations) = $class->read($fh)) {
        $ret{$local_part} = $destinations;
    }

    close($fh);

    return \%ret;
}

1;
