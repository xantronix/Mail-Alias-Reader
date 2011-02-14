package Mail::Alias::Tiny::Parser;

use strict;
use warnings;

use Mail::Alias::Tiny::Token;

use Carp;

sub parse {
    my ($class, $alias, $mode) = @_;
    my @tokens = Mail::Alias::Tiny::Token->tokenize($alias);

    my $last_token = Mail::Alias::Tiny::Token->new('T_BEGIN');
    my ($name, @destinations);

    foreach my $token (@tokens) {
        next if $token->isa(qw/T_BEGIN T_COMMENT/);

        if ($last_token->isa('T_BEGIN')) {
            confess("Expected address as name of alias, found $token->{'type'}") unless $token->isa('T_ADDRESS');
        } elsif ($token->isa('T_COMMA')) {
            confess('Unexpected comma') unless $last_token->is_value;
        } elsif ($token->isa('T_COLON')) {
            confess('Unexpected colon in .forward statement') if $mode eq 'forward';
            confess('Misplaced colon') unless $token == $tokens[2];
            confess('Unexpected colon') unless $last_token->isa('T_ADDRESS');

            $name = $last_token->{'value'};
        } elsif ($token->isa('T_WHITESPACE')) {
            confess('Unexpected whitespace') unless $last_token->is_punct;
        } elsif ($token->is_value) {
            confess("Unexpected literal value '$token->{'value'}'") unless $last_token->is_punct;

            push @destinations, $token;
        } elsif ($token->isa('T_END')) {
            confess("Unexpected end of alias statement, found $last_token->{'type'}") unless $last_token->is_value;

            last;
        }

        $last_token = $token;
    }

    confess('Declaration has no destinations') unless @destinations;

    if ($mode eq 'forward') {
        return \@destinations;
    }

    return ($name, \@destinations);
}

1;
