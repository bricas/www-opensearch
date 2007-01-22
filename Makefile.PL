use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'WWW::OpenSearch',
    'VERSION_FROM' => 'lib/WWW/OpenSearch.pm',
    'PREREQ_PM'    => {
        'Data::Page'    => 2.00,
        'Encode'        => 0,
        'LWP'           => 5.60,
        'Test::More'    => 0.32,
        'URI'           => 0,
        'XML::Feed'     => 0.08,
        'XML::LibXML'   => 1.58,
        'URI::Template' => 0,
    },
);
