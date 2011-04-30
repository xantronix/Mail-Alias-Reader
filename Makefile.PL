use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Mail::Alias::Reader',
    'VERSION_FROM' => 'lib/Mail/Alias/Reader.pm',
    'AUTHOR'       => 'Erin Schönhals (erin@cpanel.net)',
    'ABSTRACT'     => 'Parse aliases(5) and ~/.forward declarations',
    'PREREQ_PM'    => {
        'Test::More'      => 0,
        'Test::Exception' => 0
    }
);
