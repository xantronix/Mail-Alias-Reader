# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Mail::Alias::Reader',
    'VERSION_FROM' => 'lib/Mail/Alias/Reader.pm',
    'AUTHOR'       => 'Xan Tronix <xan@cpan.org>',
    'ABSTRACT'     => 'Parse aliases(5) and ~/.forward declarations',
    'PREREQ_PM'    => {
        'Test::More'      => 0,
        'Test::Exception' => 0
    }
);
