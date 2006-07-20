use strict;
use warnings;

use Test::More tests => 38;

use_ok( 'WWW::OpenSearch::Description' );

# simple 1.1 OSD
{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>Web Search</ShortName>
  <Description>Use Example.com to search the Web.</Description>
  <Tags>example web</Tags>
  <Contact>admin@example.com</Contact>
  <Url type="application/rss+xml" 
       template="http://example.com/?q={searchTerms}&amp;pw={startPage?}&amp;format=rss"/>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->shortname, 'Web Search' );
    ok( !defined $osd->longname );
    is( $osd->description, 'Use Example.com to search the Web.' );
    is( $osd->tags, 'example web' );
    is( $osd->contact, 'admin@example.com' );

    # count the urls
    is( $osd->urls, 1 );
}

# complex 1.1 OSD
{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>Web Search</ShortName>
  <Description>Use Example.com to search the Web.</Description>
  <Tags>example web</Tags>
  <Contact>admin@example.com</Contact>
  <Url type="application/rss+xml"
       template="http://example.com/?q={searchTerms}&amp;pw={startPage}&amp;format=rss"/>
  <Url type="application/atom+xml"
       template="http://example.com/?q={searchTerms}&amp;pw={startPage?}&amp;format=atom"/>
  <Url type="text/html" 
       method="post"
       template="https://intranet/search?format=html">
    <Param name="s" value="{searchTerms}"/>
    <Param name="o" value="{startIndex?}"/>
    <Param name="c" value="{itemsPerPage?}"/>
    <Param name="l" value="{language?}"/>
  </Url>
  <LongName>Example.com Web Search</LongName>
  <Image height="64" width="64" type="image/png">http://example.com/websearch.png</Image>
  <Image height="16" width="16" type="image/vnd.microsoft.icon">http://example.com/websearch.ico</Image>
  <Query role="example" searchTerms="cat" />
  <Developer>Example.com Development Team</Developer>
  <Attribution>
    Search data &amp;copy; 2005, Example.com, Inc., All Rights Reserved
  </Attribution>
  <SyndicationRight>open</SyndicationRight>
  <AdultContent>false</AdultContent>
  <Language>en-us</Language>
  <OutputEncoding>UTF-8</OutputEncoding>
  <InputEncoding>UTF-8</InputEncoding>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->shortname, 'Web Search' );
    is( $osd->longname, 'Example.com Web Search' );
    is( $osd->description, 'Use Example.com to search the Web.' );
    is( $osd->tags, 'example web' );
    is( $osd->contact, 'admin@example.com' );
    is( $osd->developer, 'Example.com Development Team' );
    is( $osd->attribution, '
    Search data &copy; 2005, Example.com, Inc., All Rights Reserved
  ' );
    is( $osd->inputencoding, 'UTF-8' );
    is( $osd->outputencoding, 'UTF-8' );
    is( $osd->language, 'en-us' );
    is( $osd->adultcontent, 'false' );
    is( $osd->syndicationright, 'open' );

    TODO: {
        local $TODO = 'Test Query and Image';

        is( $osd->query, undef );
        is( $osd->image, undef );
    };

    # count the urls
    is( $osd->urls, 3 );
}

# 1.0 OSD
{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearchdescription/1.0/">
  <Url>http://www.unto.net/aws?q={searchTerms}&amp;searchindex=Electronics
   &amp;flavor=osrss&amp;itempage={startPage}</Url>
  <Format>http://a9.com/-/spec/opensearchrss/1.0/</Format>
  <ShortName>Electronics</ShortName>
  <LongName>Amazon Electronics</LongName>
  <Description>Search for electronics on Amazon.com.</Description>
  <Tags>amazon electronics</Tags>
  <Image>http://www.unto.net/search/amazon_electronics.gif</Image>
  <SampleSearch>ipod</SampleSearch>
  <Developer>DeWitt Clinton</Developer>
  <Contact>dewitt@unto.net</Contact>
  <Attribution>Product and search data &amp;copy; 2005, Amazon, Inc.,
   All Rights Reserved</Attribution>
  <SyndicationRight>open</SyndicationRight>
  <AdultContent>false</AdultContent>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->shortname, 'Electronics' );
    is( $osd->longname, 'Amazon Electronics' );
    is( $osd->description, 'Search for electronics on Amazon.com.' );
    is( $osd->tags, 'amazon electronics' );
    is( $osd->contact, 'dewitt@unto.net' );
    is( $osd->format, 'http://a9.com/-/spec/opensearchrss/1.0/' );
    is( $osd->image, 'http://www.unto.net/search/amazon_electronics.gif' );
    is( $osd->samplesearch, 'ipod' );
    is( $osd->developer, 'DeWitt Clinton' );
    is( $osd->attribution, 'Product and search data &copy; 2005, Amazon, Inc.,
   All Rights Reserved' );
    is( $osd->syndicationright, 'open' );
    is( $osd->adultcontent, 'false' );

    # count the urls
    is( $osd->urls, 1 );
}

