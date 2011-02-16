# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Mail::Alias::Tiny' ); }

my $object = Mail::Alias::Tiny->new ();
isa_ok ($object, 'Mail::Alias::Tiny');


