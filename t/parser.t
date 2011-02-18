use strict;
use warnings;

use Mail::Alias::Tiny ();

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
        }
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
        }
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
