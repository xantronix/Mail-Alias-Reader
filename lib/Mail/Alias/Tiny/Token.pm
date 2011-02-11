package Mail::Alias::Tiny::Token;

use strict;
use warnings;

use Carp;

my @TOKEN_TYPES = (
    [ 'T_COMMENT'       => qr/#.*$/ ],
    [ 'T_STRING'        => qr/("(?:\\.|[^"\\]+)*")/ ],
    [ 'T_COMMA'         => qr/,/ ],
    [ 'T_DIRECTIVE'     => qr/:([^\:\s]+):([^\:\s,]+)/ ],
    [ 'T_COMMAND'       => qr/\|([\S]+)/ ],
    [ 'T_ADDRESS'       => qr/([a-z0-9_\-@\.*]+)/i ],
    [ 'T_COLON'         => qr/\:/ ],
    [ 'T_FILE'          => qr/([\S]+)/ ],
    [ 'T_WHITESPACE'    => qr/\s+/ ],
);

my @TOKEN_STRING_TYPES = (
    [ 'T_DIRECTIVE'     => qr/:([^\:\s]+):\s*(.*)/ ],
    [ 'T_COMMAND'       => qr/\|(.*)/ ],
    [ 'T_ADDRESS'       => qr/([^\/]+)/ ],
    [ 'T_FILE'          => qr/(.*)/ ]
);

sub new {
    my ($class, $type) = @_;

    return bless {
        'type' => $type
    }, $class;
}

sub isa {
    my ($self, @types) = @_;

    foreach my $type (@types) {
        return 1 if $self->{'type'} eq $type;
    }

    return 0;
}

sub is_value {
    return shift->isa(qw/T_DIRECTIVE T_COMMAND T_ADDRESS T_FILE/);
}

sub is_punct {
    return shift->isa(qw/T_BEGIN T_END T_COLON T_COMMA T_WHITESPACE/);
}

sub is_address {
    return shift->isa('T_ADDRESS');
}

sub is_command {
    return shift->isa('T_COMMAND');
}

sub is_file {
    return shift->isa('T_FILE');
}

sub to_string {
    my ($self) = @_;

    return ":$self->{'name'}:$self->{'value'}" if $self->{'type'} eq 'T_DIRECTIVE';
    return "|$self->{'value'}"                 if $self->{'type'} eq 'T_COMMAND';

    return $self->{'value'};
}

sub tokenize_for_types {
    my ($class, $buf, @types) = @_;
    my @tokens;

    match: while ($buf) {
        foreach my $type (@types) {
            next unless $buf =~ s/^$type->[1]//;

            my $token = bless {
                'type' => $type->[0],
            }, $class;

            if ($type->[0] eq 'T_DIRECTIVE') {
                @{$token}{qw(name value)} = ($1, $2);
            } else {
                $token->{'value'} = $1;
            }

            push @tokens, $token;

            next match;
        }

        confess("Syntax error: '$buf'");
    }

    return @tokens;
}

sub tokenize {
    my ($class, $buf) = @_;

    #
    # Perform first stage tokenization on the input.
    #
    my @tokens = $class->tokenize_for_types($buf, @TOKEN_TYPES);

    foreach my $token (@tokens) {
        #
        # Perform second stage tokenization on any T_STRING tokens found.  As the aliases(5)
        # format lacks a string literal type, a second pass is required to parse the quote
        # delimited string out for a more specific type.
        #
        if ($token->{'type'} eq 'T_STRING') {
            $token->{'value'} =~ s/^"(.*)"$/$1/;

            my ($new_token) = $class->tokenize_for_types($token->{'value'}, @TOKEN_STRING_TYPES);

            @{$token}{keys %{$new_token}} = values %{$new_token};
        }
    }

    return (
        $class->new('T_BEGIN'),
        @tokens,
        $class->new('T_END')
    );
}

1;
