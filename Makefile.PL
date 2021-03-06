# $id$
use ExtUtils::MakeMaker;
require 5.6.0;


WriteMakefile(
    'NAME'         => "GOBO",
    'DISTNAME'         => "GOBO",
    'ABSTRACT'     => 'Perl library for GO and OBO',
    'AUTHOR'       => 'Chris Mungall <cjm@fruitfly.org>',
    'VERSION_FROM' => "GOBO.pm",
    'PREREQ_PM'    => {
        'DateTime::Format::ISO8601' => '0.0.7',
        'Test::Deep'                 => '0.106',
        'Graph'                     => '0.94',
        'List::MoreUtils'           => '0.22',
        'Moose'                     => '1.08',
        'Set::Object'               => '1.28',
    },
    'EXE_FILES'    => [
        qw(
                                    bin/go-gaf-inference.pl
                                    bin/go-slimdown.pl
                                    bin/gobo-make-lucene-index.pl
                                   )
    ],
    'dist'         => { 
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9f" 
    },
    clean => {
        FILES => 'GOBO-$(VERSION).tar.gz',
    },
    );

