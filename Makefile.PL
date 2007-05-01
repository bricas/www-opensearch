use inc::Module::Install 0.65;

name 'WWW-OpenSearch';
all_from 'lib/WWW/OpenSearch.pm';

requires 'Data::Page'  => 2.00;
requires 'LWP'         => 5.60;
requires 'XML::Feed'   => 0.08;
requires 'XML::LibXML' => 1.58;
requires 'Encode';
requires 'URI';
requires 'URI::Template';
requires 'Test::More';

auto_install;
WriteAll;
