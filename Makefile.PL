use inc::Module::Install 0.68;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/WWW/OpenSearch.pm > README' );
}

name 'WWW-OpenSearch';
all_from 'lib/WWW/OpenSearch.pm';

requires 'Data::Page'  => 2.00;
requires 'LWP'         => 5.60;
requires 'XML::Feed'   => 0.08;
requires 'XML::LibXML' => 1.58;
requires 'Encode';
requires 'URI';
requires 'URI::Template';

test_requires 'Test::More';

auto_install;
WriteAll;
