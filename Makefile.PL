use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'WWW::OpenSearch',
    'VERSION_FROM' => 'lib/WWW/OpenSearch.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	LWP => 5.60,
	Data::Page => 2.00,
	XML::RSS::LibXML => 0.05,
	XML::LibXML => 1.58,
    },
);
