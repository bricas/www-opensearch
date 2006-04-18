use strict;
use Test::More;

my $url = $ENV{OPENSEARCH_URL};
unless ($url) {
    Test::More->import(skip_all => "OPENSEARCH_URL not set");
    exit;
}

# XXX This is not testing, but for debugging :)
plan 'no_plan';

use WWW::OpenSearch;

my $engine = WWW::OpenSearch->new($url);
ok $engine;
ok $engine->ShortName, $engine->ShortName;

my $feed = $engine->search("iPod");
ok $feed;
ok $feed->channel->{title}, $feed->channel->{title};
ok $feed->channel->{link}, $feed->channel->{link};
ok $engine->pager->entries_per_page, "items per page " . $engine->pager->entries_per_page;
ok $engine->pager->total_entries, "total entries " . $engine->pager->total_entries;


