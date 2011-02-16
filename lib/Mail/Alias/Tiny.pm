package Mail::Alias::Tiny;

use strict;
use warnings;

use Mail::Alias::Tiny::Parser ();

use Carp;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    $VERSION     = '0.01';
    @ISA         = qw(Exporter);

    @EXPORT      = ();
    @EXPORT_OK   = ();
    %EXPORT_TAGS = ();
}

sub open {
    my ($class, %opts) = @_;
    $opts{'mode'} ||= 'aliases';

    confess('Unknown parsing mode') unless $opts{'mode'} =~ /^aliases|forward$/;

    my $fh;

    if (defined $opts{'file'}) {
        open($fh, '<', $opts{'file'}) or confess("Unable to open aliases file $opts{'file'}: $!");
    } elsif (defined $opts{'handle'}) {
        $fh = $opts{'handle'};
    } else {
        confess('No file or file handle specified');
    }

    return bless {
        'mode'   => $opts{'mode'},
        'handle' => $fh
    }, $class;
}

sub read {
    my ($self) = @_;

    while (my $line = readline($self->{'handle'})) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next unless $line;
        next if $line =~ /^(#|$)/;

        return Mail::Alias::Tiny::Parser->parse($line, $self->{'mode'});
    }

    return;
}

sub close {
    close shift->{'handle'};
}

1;
