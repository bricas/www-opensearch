use strict;
use Test::More;

my $url = $ENV{OPENSEARCH_URL};
unless ($url) {
    Test::More->import(skip_all => "OPENSEARCH_URL not set");
    exit;
}

plan 'no_plan';

use WWW::OpenSearch;

my $engine = WWW::OpenSearch->new($url);
$engine->pager->entries_per_page(20);
$engine->pager->current_page(2);
my $query = $engine->setup_query("foo");
like $query, qr/page=2/, "page=2";

