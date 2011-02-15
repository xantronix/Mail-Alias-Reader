package Mail::Alias::Tiny::Parser;

use strict;
use warnings;

use Mail::Alias::Tiny::Token;

use Carp;

sub _parse_forward_statement {
    my ($tokens) = @_;
    my @destinations;

    my $last_token = Mail::Alias::Tiny::Token->new('T_BEGIN');

    foreach my $token (@{$tokens}) {
        next if $token->isa(qw/T_BEGIN T_COMMENT T_WHITESPACE/);

        if ($token->is_value) {
            confess('Unexpected value') unless $last_token->is_punct;

            push @destinations, $token;
        } elsif ($token->isa('T_COMMA')) {
            confess('Unexpected comma') unless $last_token->is_value;
        } elsif ($token->isa('T_END')) {
            confess('Unexpected end of statement') unless $last_token->is_value;

            last;
        } else {
            confess("Unexpected $token->{'type'}");
        }

        $last_token = $token;
    }

    confess('Statement contains no destinations') unless @destinations;

    return \@destinations;
}

sub _parse_aliases_statement {
    my ($tokens) = @_;
    my ($name, @destinations);

    my $last_token = Mail::Alias::Tiny::Token->new('T_BEGIN');

    foreach my $token (@{$tokens}) {
        next if $token->isa(qw/T_BEGIN T_COMMENT T_WHITESPACE/);

        if ($last_token->isa('T_BEGIN')) {
            confess("Expected address as name of alias, found $token->{'type'}") unless $token->isa('T_ADDRESS');
        } elsif ($token->isa('T_COLON')) {
            confess('Unexpected colon') unless $last_token->isa('T_ADDRESS');

            $name = $last_token->{'value'};
        } elsif ($token->isa('T_COMMA')) {
            confess('Unexpected comma') unless $last_token->is_value;
        } elsif ($token->isa('T_END')) {
            confess('Unexpected end of aliases statement') unless $last_token->is_value;

            last;
        } elsif ($token->is_value) {
            push @destinations, $token;
        }

        $last_token = $token;
    }

    confess('Alias statement has no name') unless defined $name;
    confess('Aliases statement has no destinations') unless @destinations;

    return ($name, \@destinations);
}

sub parse {
    my ($class, $statement, $mode) = @_;
    my @tokens = Mail::Alias::Tiny::Token->tokenize($statement);

    return _parse_forward_statement(\@tokens) if $mode eq 'forward';
    return _parse_aliases_statement(\@tokens) if $mode eq 'aliases';

    confess("Invalid parsing mode $mode specified");
}

1;
