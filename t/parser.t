use strict;
use warnings;

use Mail::Alias::Tiny ();
use Mail::Alias::Tiny::Token ();
use Mail::Alias::Tiny::Parser ();

use Test::More ('no_plan');
use Test::Exception;

sub open_reader {
    my ($mode, @statements) = @_;

    pipe my ($out, $in) or die("Unable to pipe(): $!");
    my $pid = fork();

    if ($pid == 0) {
        close($out);

        foreach my $statement (@statements) {
            print {$in} "$statement\n";
        }

        exit(0);
    } elsif (!defined($pid)) {
        die("Unable to fork(): $!");
    }

    close($in);

    my $reader = Mail::Alias::Tiny->open(
        'handle' => $out,
        'mode'   => $mode
    );

    return ($reader, $pid);
}

#
# Coverage for aliases(5) mode
#
{
    my %TESTS = (
        'foo: bar, baz' => sub {
            my ($name, $destinations) = $_[0]->read;

            ok($name eq 'foo', "Alias name in '$_[1]' is '$name'");
        },

        'bar baz' => sub {
            my ($reader, $statement) = @_;

            throws_ok {
                $reader->read
            } qr/Alias statement has no name/, "'$statement' produces an error";
        },

        '/dev/null: this, will, not, work' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Expected address as name of alias/, "Mail::Alias::Tiny::Parser needs an address as name of alias"
        },

        'this, should, : not, work' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Unexpected colon/, "Mail::Alias::Tiny::Parser is intolerant of misplaced colons";
        },

        'this: should: not: work' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Too many colons/, "Mail::Alias::Tiny::Parser is intolerant of multiple colons";
        },

        'this,,should,,not,,work' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Unexpected comma/, "Mail::Alias::Tiny::Parser is intolerant of misplaced commas";
        },

        'this, should, fail:' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Unexpected end of alias/, "Mail::Alias::Tiny::Parser wants a value at the end of statement";
        },
    );

    my @STATEMENTS = keys %TESTS;
    my ($reader, $pid) = open_reader('aliases', @STATEMENTS);

    foreach my $statement (@STATEMENTS) {
        my $test = $TESTS{$statement};

        $test->($reader, $statement);
    }

    $reader->close;

    waitpid($pid, 0);
}

#
# Coverage for ~/.forward mode
#
{
    my %TESTS = (
        'foo, bar, baz' => sub {
            my ($reader, $statement) = @_;
            my $destinations = $reader->read;

            ok($destinations->[1]->{'value'} eq 'bar', "Second destination in '$statement' is 'bar'");
        },

        'foo: cats' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read;
            } qr/Unexpected T_COLON/, "Parsing in 'forward' mode will not allow aliases(5) names";
        },

        'foo bar baz' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Unexpected value/, "Values in 'forward' mode not separate by commas are illegal";
        },

        'foo,,' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Unexpected comma/, "Multiple sequential comments in 'forward' mode are illegal";
        },

        'foo,' => sub {
            my ($reader) = @_;

            throws_ok {
                $reader->read
            } qr/Unexpected end of statement/, "Comma at end of statement in 'forward' mode is illegal";
        },
    );

    my @STATEMENTS = keys %TESTS;
    my ($reader, $pid) = open_reader('forward', @STATEMENTS);

    foreach my $statement (keys %TESTS) {
        my $test = $TESTS{$statement};

        $test->($reader, $statement);
    }

    $reader->close;

    waitpid($pid, 0);
}

#
# Some more in-depth coverage of internal details of ~/.forward parsing mode
#
{
    my @tokens = map { Mail::Alias::Tiny::Token->new($_) } qw(T_BEGIN T_WHITESPACE);

    throws_ok {
        Mail::Alias::Tiny::Parser::_parse_forward_statement(\@tokens)
    } qr/Statement contains no destinations/, "Mail::Alias::Tiny::Parser expects forward statements to have values";
}

#
# Internal details of aliases(5) parsing mode
#
{
    throws_ok {
        my @tokens = map { Mail::Alias::Tiny::Token->new($_) } qw(T_BEGIN T_ADDRESS T_COLON T_STRING T_END);

        Mail::Alias::Tiny::Parser::_parse_aliases_statement(\@tokens)
    } qr/Unexpected T_STRING/, "Mail::Alias::Tiny::Parser freaks out if it receives an unprocessed T_STRING";
}

#
# Trying really hard to trip up the parser
#
{
    throws_ok {
        Mail::Alias::Tiny::Parser->parse('foo', 'bar');
    } qr/Invalid parsing mode/, "Mail::Alias::Tiny::Parser likes to have a valid parsing mode passed";
}
