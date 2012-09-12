use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'PhotoUploader',
    AUTHOR       => 'equinox79',
    VERSION_FROM => 'lib/Yancha/Client/PhotoUploader.pm',
    PL_FILES     => {},
    PREREQ_PM    => {
        'Encode'                => 0,
        'File::Monitor::Lite'   => 0,
        'HTTP::Request::Common' => 0,
        'JSON'                  => 0,
        'LWP::UserAgent'        => 0,
        'Log::Minimal'          => 0,
        'version'               => 0,
        'Data::Printer'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Yancha-*' },
);

