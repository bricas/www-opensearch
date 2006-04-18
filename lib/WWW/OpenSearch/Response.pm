package WWW::OpenSearch::Response;

use strict;
use warnings;

use base qw( HTTP::Response Class::Accessor::Fast );

use XML::Feed;
use Data::Page;

__PACKAGE__->mk_accessors( qw( feed pager parent ) );

sub new {
    my $class    = shift;
    my $parent   = shift;
    my $response = shift;
    
    my $self = bless $response, $class;

    $self->parent( $parent );
    return $self unless $self->is_success;
    
    $self->parse_response;
    
    return $self;
}

sub parse_response {
    my $self = shift;

    my $content = $self->content;
    my $feed    = XML::Feed->parse( \$content );

    return if XML::Feed->errstr;
    $self->feed( $feed );
    
    $self->parse_feed;
}

sub parse_feed {
    my $self  = shift;
    my $pager = Data::Page->new;

    my $feed   = $self->feed;
    my $format = $feed->format;
    my $ns     = $self->parent->description->ns;
    
    # TODO
    # adapt these for any number of opensearch elements in
    # the feed or in each entry
    
    if( my $atom = $feed->{ atom } ) {
        my $total   = $atom->get( $ns, 'totalResults' );
        my $perpage = $atom->get( $ns, 'itemsPerPage' );
        my $start   = $atom->get( $ns, 'startIndex' );
        
        undef $start if $start eq 'null';
        
        $pager->total_entries( $total );
        $pager->entries_per_page( $perpage );
        $pager->current_page( $start ? ( $start - 1 ) / $perpage + 1 : 0 )
    }
    elsif( my $rss = $feed->{ rss } ) {
      	if ( my $page = $rss->channel->{ $ns } ) {
            $pager->total_entries(    $page->{ totalResults } );
            $pager->entries_per_page( $page->{ itemsPerPage } );
            my $start = $page->{ startIndex };
            $pager->current_page( $start ? ( $start - 1 ) / $page->{ itemsPerPage } + 1 : 0 )
        }
    }    
    $self->pager( $pager );
}

# TODO
# handle pervious/next page on POST

sub next_page {
    my $self  = shift;
    my $pager = $self->pager;
    my $page  = $pager->next_page;
    return unless $page;
    
    my $link = $self->_get_link( 'next' );
    return $self->parent->do_search( $link, $self->request->method ) if $link;
    
    my $url   = $self->request->uri->clone;
    my %query = $url->query_form;
    my $param;

    my $template = $self->parent->description->get_best_url;

    if( $param = $template->macros->{ startPage } ) {
        $query{ $param } = $pager->next_page
    }
    elsif( $param = $template->macros->{ startIndex } ) {
        $query{ $param } ? $query{ $param } += $pager->entries_per_page
                         : $query{ $param }  = $pager->entries_per_page + 1;
    }

    $url->query_form( \%query );
    return $self->parent->do_search( $url, $self->request->method );
}

sub previous_page {
    my $self  = shift;
    my $pager = $self->pager;
    my $page  = $pager->previous_page;
    return unless $page;

    my $link = $self->_get_link( 'previous' );
    return $self->parent->do_search( $link, $self->request->method ) if $link;
    
    my $url   = $self->request->uri->clone;
    my %query = $url->query_form;
    my $param;
    
    my $template = $self->parent->description->get_best_url;
    
    if( $param = $template->macros->{ startPage } ) {
        $query{ $param } = $pager->previous_page
    }
    elsif( $param = $template->macros->{ startIndex } ) {
        $query{ $param } ? $query{ $param } -= $pager->entries_per_page
                         : $query{ $param }  = 1;
    }
    
    $url->query_form( \%query );
    return $self->parent->do_search( $url, $self->request->method );
}

sub _get_link {
    my $self = shift;
    my $type = shift;
    my $feed = $self->feed->{ atom };
    
    return unless $feed;
    
    for( $feed->link_libxml ) {
        return $_->get( 'href' ) if $_->get( 'rel' ) eq $type;
    }
    
}

1;