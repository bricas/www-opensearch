use strict;
use warnings;

use Test::More tests => 27;

use_ok( 'WWW::OpenSearch::Description' );
use_ok( 'WWW::OpenSearch::Url' );

{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <Url type="application/rss+xml" 
       template="http://example.com/?q={searchTerms}&amp;pw={startPage?}&amp;format=rss"/>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->urls, 1 );

    my( $url ) = $osd->urls;
    isa_ok( $url, 'WWW::OpenSearch::Url' );
    is( $url->type, 'application/rss+xml' );
    is( lc $url->method, 'get' );
    is( $url->template, 'http://example.com/?q=%7BsearchTerms%7D&pw=%7BstartPage%7D&format=rss' );
}

{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
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
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->urls, 3 );

    {
        my $url = $osd->url->[ 0 ];
        isa_ok( $url, 'WWW::OpenSearch::Url' );
        is( $url->type, 'application/rss+xml' );
        is( lc $url->method, 'get' );
        is( $url->template, 'http://example.com/?q=%7BsearchTerms%7D&pw=%7BstartPage%7D&format=rss' );
    }

    {
        my $url = $osd->url->[ 1 ];
        isa_ok( $url, 'WWW::OpenSearch::Url' );
        is( $url->type, 'application/atom+xml' );
        is( lc $url->method, 'get' );
        is( $url->template, 'http://example.com/?q=%7BsearchTerms%7D&pw=%7BstartPage%7D&format=atom' );
    }

    {
        my $url = $osd->url->[ 2 ];
        isa_ok( $url, 'WWW::OpenSearch::Url' );
        is( $url->type, 'text/html' );
        is( lc $url->method, 'post' );
        is( $url->template, 'https://intranet/search?format=html' );
    }
}

{
    my $description = q(<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearchdescription/1.0/">
  <Url>http://www.unto.net/aws?q={searchTerms}&amp;searchindex=Electronics&amp;flavor=osrss&amp;itempage={startPage}</Url>
</OpenSearchDescription>
);

    my $osd = WWW::OpenSearch::Description->new( $description );
    isa_ok( $osd, 'WWW::OpenSearch::Description' );
    is( $osd->urls, 1 );

    my( $url ) = $osd->urls;
    isa_ok( $url, 'WWW::OpenSearch::Url' );
    is( lc $url->method, 'get' );
    is( $url->template, 'http://www.unto.net/aws?q=%7BsearchTerms%7D&searchindex=Electronics&flavor=osrss&itempage=%7BstartPage%7D' );
}

