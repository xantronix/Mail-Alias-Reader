use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Mail::Alias::Tiny',
    VERSION_FROM => 'lib/Mail/Alias/Tiny.pm', # finds \$VERSION
    AUTHOR       => 'Erin Schönhals (erin@cpanel.net)',
    ABSTRACT     => 'Parse aliases(5) and ~/.forward declarations',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
