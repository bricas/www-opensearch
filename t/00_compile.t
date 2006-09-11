use strict;
use Test::More tests => 6;

BEGIN {
    use_ok 'WWW::OpenSearch';
    use_ok 'WWW::OpenSearch::Description';
    use_ok 'WWW::OpenSearch::Response';
    use_ok 'WWW::OpenSearch::Url';
    use_ok 'WWW::OpenSearch::Query';
    use_ok 'WWW::OpenSearch::Image';
}
