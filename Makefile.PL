use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'WWW::OpenSearch',
    'VERSION_FROM' => 'lib/WWW/OpenSearch.pm', # finds $VERSION
    'PREREQ_PM'    => {
	Data::Page  => 2.00,
	LWP         => 5.60,
	Test::More  => 0.32,
	URI         => 0,
	XML::Feed   => 0.08,
	XML::LibXML => 1.58
    },
);
