package Mail::Alias::Tiny::Token;

use strict;
use warnings;

use Carp;

=head1 NAME

Mail::Alias::Tiny::Token

=head1 DESCRIPTION

Mail::Alias::Tiny::Token is not only the class represents an aliases(5) parser
token, but also itself is returned by L<Mail::Alias::Tiny> as a representation
of a mail alias destination.  For the purposes of this documentation, only the
public-facing methods which facilitate the usage of instances of this class
shall be discussed.

=cut

my @TOKEN_TYPES = (
    [ 'T_COMMENT'       => qr/#\s*(.*)$/ ],
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
    return shift->isa(qw/T_BEGIN T_END T_COLON T_COMMA/);
}

=head1 DETERMINING MAIL DESTINATION TYPE

A variety of methods are provided to allow one to infer the type of a mail
alias (parser token) returned.

=over

=item $destination->is_address()

Returns true if the mail destination described by the current token is a local
part or fully qualified mail address.

=cut
sub is_address {
    return shift->isa('T_ADDRESS');
}

=item $destination->is_directive()

Returns true if the mail destination described by the current token is a
mail transfer agent directive.

=cut
sub is_directive {
    return shift->isa('T_DIRECTIVE');
}

=item $destination->is_command()

Returns true if the mail destination described by the current token is a
command to which mail messages should be piped.

=cut
sub is_command {
    return shift->isa('T_COMMAND');
}

=item $destination->is_file()

Returns true if the mail destination described by the current token is a file
to which mail messages should be appended.

=back

=cut
sub is_file {
    return shift->isa('T_FILE');
}

=head1 CONVERTING THE MAIL DESTINATION TO A STRING

=over

=item $destination->to_value()

Returns a parsed and unescaped logical representation of the mail alias
destination that was originally parsed to yield the current token object.

=cut
sub to_value {
    return shift->{'value'};
}

=item $destination->to_string()

Returns a string representation of the mail alias destination that was
originally parsed to yield the current token object.

=back

=cut
sub to_string {
    my ($self) = @_;
    my $ret;

    #
    # Since not every token type has a "value", per se, lazy evaluation is
    # necessary to prevent a Perl runtime warning when evaluating the 'T_COMMENT'
    # part of this hash when dealing with tokens that are anything other than a
    # comment.
    #
    my %VALUES = (
        'T_COMMENT'    => sub { "# $self->{'value'}" },
        'T_COMMA'      => sub { ',' },
        'T_COLON'      => sub { ':' },
        'T_WHITESPACE' => sub { ' ' }
    );

    return $VALUES{$self->{'type'}}->() if exists $VALUES{$self->{'type'}};

    if (defined $self->{'string'}) {
        #
        # If this token contains its original string representation, then
        # use that directly.  That way, there's no guesswork involved in how to
        # properly escape the data for recording to a file.
        #
        $ret = $self->{'string'};
    } elsif ($self->isa('T_DIRECTIVE')) {
        $ret = ":$self->{'name'}:$self->{'value'}";
    } elsif ($self->isa('T_COMMAND')) {
        $ret = "|$self->{'value'}";
    } else {
        $ret = $self->{'value'};
    }

    #
    # If the data to be returned contains spaces, then wrap it with double quotes
    # before returning it to the user.
    #
    $ret =~ s/^(.*)$/"$1"/ if $ret =~ /\s/;

    return $ret;
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

    return \@tokens;
}

sub tokenize {
    my ($class, $buf) = @_;

    my @STRING_ESCAPE_SEQUENCES = (
        [ qr/\\(0\d*)/        => sub { pack 'W', oct($1) } ],
        [ qr/\\(0x[0-9a-f]+)/ => sub { pack 'H', hex($1) } ],
        [ qr/\\r/             => sub { "\r" } ],
        [ qr/\\n/             => sub { "\n" } ],
        [ qr/\\t/             => sub { "\t" } ],
        [ qr/\\(.)/           => sub { $1 } ]
    );

    #
    # Perform first stage tokenization on the input.
    #
    my $tokens = $class->tokenize_for_types($buf, @TOKEN_TYPES);

    foreach my $token (@{$tokens}) {
        #
        # Perform second stage tokenization on any T_STRING tokens found.  As the aliases(5)
        # format lacks a string literal type, a second pass is required to parse the quote
        # delimited string out for a more specific type.
        #
        if ($token->isa('T_STRING')) {
            $token->{'value'} =~ s/^"(.*)"$/$1/;
            $token->{'string'} = $token->{'value'};

            #
            # Parse for any escape sequences that may be present.
            #
            foreach my $sequence (@STRING_ESCAPE_SEQUENCES) {
                my ($pattern, $subst) = @{$sequence};

                $token->{'value'} =~ s/$pattern/$subst->()/eg;
            }

            #
            # Create a new token from the second pass parsing step for the string
            # contents, copying the data directly into the existing token (so as to
            # not lose the previous reference).
            #
            my $new_token = $class->tokenize_for_types($token->{'value'}, @TOKEN_STRING_TYPES)->[0];

            @{$token}{keys %{$new_token}} = values %{$new_token};
        }
    }

    return [
        $class->new('T_BEGIN'),
        @{$tokens},
        $class->new('T_END')
    ];
}

1;

__END__

=head1 AUTHOR

Erin Schoenhals E<lt>erin@cpanel.netE<gt>
