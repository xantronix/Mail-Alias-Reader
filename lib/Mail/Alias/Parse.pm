package Mail::Alias::Parse;

use strict;
use warnings;

my @TOKEN_TYPES = (
    [ 'T_COMMENT'       => qr/#.*$/ ],
    [ 'T_STRING'        => qr/"((?:[^"\\]++|\\.)*+)"/ ],
    [ 'T_COMMA'         => qr/,/ ],
    [ 'T_INCLUDE'       => qr/:include:([^\:\s,]+)/ ],
    [ 'T_FAIL'          => qr/:fail:([^\:\s,]+)/ ],
    [ 'T_COMMAND'       => qr/\|([\S]+)/ ],
    [ 'T_ADDRESS'       => qr/([a-z0-9_\-@\.*]+)/i ],
    [ 'T_COLON'         => qr/\:/ ],
    [ 'T_FILE'          => qr/([\S]+)/ ],
    [ 'T_WHITESPACE'    => qr/\s+/ ]
);

my @TOKEN_STRING_TYPES = (
    [ 'T_INCLUDE'       => qr/:include:(.*)/ ],
    [ 'T_FAIL'          => qr/:fail:(.*)/ ],
    [ 'T_COMMAND'       => qr/\|(.*)/ ],
    [ 'T_ADDRESS'       => qr/([^\/]+)/ ],
    [ 'T_FILE'          => qr/(.*)/ ]
);

sub _is {
    my ($token, @types) = @_;

    foreach (@types) {
        return 1 if $token->{'type'} eq $_;
    }

    return 0;
}

sub _is_value {
    _is(shift, qw/T_INCLUDE T_FAIL T_COMMAND T_ADDRESS T_FILE/);
}

sub _is_punct {
    my ($token) = @_;

    return 1 unless defined $token;
    return _is($token, qw/T_BEGIN T_END T_COLON T_COMMA T_WHITESPACE/);
}

sub _tokenize_by_type {
    my ($buf, @types) = @_;
    my @tokens;

    match: while ($buf) {
        foreach my $type (@types) {
            next unless $buf =~ s/^$type->[1]//;

            push @tokens, {
                'type'  => $type->[0],
                'value' => $1
            };

            next match;
        }

        die("Syntax error: '$buf'");
    }

    return @tokens;
}

sub tokenize {
    my ($class, $buf) = @_;

    #
    # Perform first stage tokenization on the input.
    #
    my @tokens = _tokenize_by_type($buf, @TOKEN_TYPES);

    foreach my $token (@tokens) {
        #
        # Perform second stage tokenization on any T_STRING tokens found.  As the aliases(5)
        # format lacks a string literal type, a second pass is required to parse the quote
        # delimited string out for a more specific type.
        #
        if ($token->{'type'} eq 'T_STRING') {
            my ($new_token) = _tokenize_by_type($token->{'value'}, @TOKEN_STRING_TYPES);

            @{$token}{qw/type value/} = @{$new_token}{qw/type value/};
        }
    }

    return (
        {'type' => 'T_BEGIN'},
        @tokens,
        {'type' => 'T_END'}
    );
}

sub parse {
    my ($class, $alias) = @_;
    my @tokens = $class->tokenize($alias);

    my $last_token = {'type' => 'T_BEGIN'};
    my ($name, @values);

    foreach my $token (@tokens) {
        next if _is($token, qw/T_BEGIN T_COMMENT/);

        if (_is($last_token, 'T_BEGIN')) {
            die("Expected address as name of alias, found $token->{'type'}") unless _is($token, 'T_ADDRESS');

            $name = $token->{'value'};
        } elsif (_is($token, 'T_COMMA')) {
            die('Unexpected comma') unless _is_value($last_token);
        } elsif (_is($token, 'T_COLON')) {
            die('Unexpected colon') unless _is($last_token, 'T_ADDRESS');
            die('Misplaced colon') unless $token == $tokens[2];
        } elsif (_is($token, 'T_WHITESPACE')) {
            die('Unexpected whitespace') unless _is_punct($last_token);
        } elsif (_is_value($token)) {
            die("Unexpected literal value '$token->{'value'}") unless _is_punct($last_token);

            push @values, $token;
        } elsif (_is($token, 'T_END')) {
            die("Unexpected end of alias statement, found $last_token->{'type'}") unless _is_value($last_token);

            return ($name, @values);
        }

        $last_token = $token;
    }

    die('Terrible failure');
}

sub read_file {
    my ($class, $file) = @_;
    my %ret;

    open(my $fh, '<', $file) or die("Unable to open mail aliases file $file for reading");

    while (my $line = readline($fh)) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next unless $line;
        next if $line =~ /^(#|$)/;

        my ($name, @values) = $class->parse($line);

        $ret{$name} = \@values;
    }

    close($fh);

    return \%ret;
}

1;
