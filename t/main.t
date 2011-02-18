use strict;
use warnings;

use Mail::Alias::Tiny ();

use File::Temp qw(mkstemp);

use Test::More ('no_plan');
use Test::Exception;

throws_ok {
    Mail::Alias::Tiny->open(
        'mode' => 'foo',
        'file' => 'bar'
    )
} qr/Unknown parsing mode/, 'Mail::Alias::Tiny->open() fails when passed unknown mode';

throws_ok {
    Mail::Alias::Tiny->open(
        'mode' => 'aliases',
        'file' => '/dev/null/this/file/cannot/possibly/exist'
    )
} qr/Unable to open aliases file/, 'Mail::Alias::Tiny->open() fails when file open() fails';

throws_ok {
    Mail::Alias::Tiny->open(
        'mode' => 'aliases'
    )
} qr/No file or file handle specified/, 'Mail::Alias::Tiny->open() fails when no file or file handle is passed';

lives_ok {
    open(my $fh, '<', '/dev/null') or die("Cannot open /dev/null: $!");

    Mail::Alias::Tiny->open(
        'handle' => $fh
    )->close;
} 'Mail::Alias::Tiny->open() defaults to a mode of "aliases"';

{
    my %TESTS = (
        'foo'  => 'bar baz',
        'name' => '"|destination meow"',
        'this' => 'should@work.mil'
    );

    my ($fh, $file) = mkstemp('/tmp/.mail-alias-parser-test-XXXXXX') or die("Cannot create temporary file: $!");

    print {$fh} "          \n"; # Throw in a line of whitespace to attempt to trip up the parser
    print {$fh} "# This entire line is a comment and shouldn't show up in \%aliases below\n";

    foreach my $alias (sort keys %TESTS) {
        print {$fh} "$alias: $TESTS{$alias}\n";
    }

    close $fh;

    my $reader = Mail::Alias::Tiny->open(
        'mode' => 'aliases',
        'file' => $file
    );

    my %aliases;

    while (my ($name, $destinations) = $reader->read) {
        $aliases{$name} = $destinations;
    }

    $reader->close;
    unlink($file);

    ok(1, 'Mail::Alias::Tiny->read() seems to cope well with empty lines by ignoring them');
    ok(keys %aliases == keys %TESTS, 'Mail::Alias::Tiny->read() returns the correct number of results');

    foreach my $test (keys %TESTS) {
        ok(exists $aliases{$test}, qq{Mail::Alias::Tiny->read() found an alias for "$test"});
    }
}
