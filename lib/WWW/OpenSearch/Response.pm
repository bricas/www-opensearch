package WWW::OpenSearch::Response;

use strict;
use warnings;

use base qw( HTTP::Response Class::Accessor::Fast );

use XML::Feed;
use URI;
use Data::Page;

__PACKAGE__->mk_accessors( qw( feed pager parent ) );

=head1 NAME

WWW::OpenSearch::Response - Encapsulate a response received from
an A9 OpenSearch compatible engine

=head1 SYNOPSIS
    
    use WWW::OpenSearch;
    
    my $url = "http://bulkfeeds.net/opensearch.xml";
    my $engine = WWW::OpenSearch->new($url);
    
    # Retrieve page 4 of search results for "iPod"
    my $response = $engine->search("iPod",{ startPage => 4 });
    for my $item (@{$response->feed->items}) {
        print $item->{description};
    }
    
    # Retrieve page 3 of results
    $response = $response->previous_page;
    
    # Retrieve page 5 of results
    $response = $response->next_page;
    
=head1 DESCRIPTION

WWW::OpenSearch::Response is a module designed to encapsulate a
response received from an A9 OpenSearch compatible engine.
See http://opensearch.a9.com/spec/1.1/response/ for details.

=head1 CONSTRUCTOR

=head2 new( $parent, $response )

Constructs a new instance of WWW::OpenSearch::Response. Arguments
include the WWW::OpenSearch object which initiated the search (parent)
and the HTTP::Response returned by the search request.

=head1 METHODS

=head2 parse_response( )

Parses the content of the HTTP response using XML::Feed. If successful,
parse_feed( ) is also called.

=head2 parse_feed( )

Parses the XML::Feed originally parsed from the HTTP response content.
Sets the pager object appropriately.

=head2 previous_page( ) / next_page( )

Performs another search on the parent object, returning a
WWW::OpenSearch::Response instance containing the previous/next page
of results. If the current response includes a &lt;link rel="previous/next"
href="..." /&gt; tag, the page will simply be the parsed content of the URL
specified by the tag's href attribute. However, if the current response does not
include the appropriate link, a new query is constructed using the startPage
or startIndex query arguments.

=head2 _get_link( $type )

Gets the href attribute of the first link whose rel attribute
is equal to $type.

=head1 ACCESSORS

=head2 feed( )

=head2 pager( )

=head2 parent( )

=head1 AUTHOR

=over 4

=item * Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Tatsuhiko Miyagawa and Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

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

sub next_page {
    my $self  = shift;
    return $self->_get_page( 'next' );
}

sub previous_page {
    my $self  = shift;
    return $self->_get_page( 'previous' );
}

sub _get_page {
    my( $self, $direction ) = @_;    
    my $pager       = $self->pager;
    my $pagermethod = "${direction}_page";
    my $page        = $pager->$pagermethod;
    return unless $page;
    
    my $request = $self->request;
    my $method  = lc $request->method;

    if( $method ne 'post' ) { # force query build on POST
        my $link = $self->_get_link( $direction );
        return $self->parent->do_search( $link, $method ) if $link;
    }
    
    my $template = $self->parent->description->get_best_url;
    my( $param, $query );
    if( $method eq 'post' ) {
        my $uri = URI->new( 'http://foo.com/?' . $request->content );
        $query = { $uri->query_form };
    }
    else {
        $query = { $self->request->uri->query_form };
    }

    if( $param = $template->macros->{ startPage } ) {
        $query->{ $param } = $pager->$pagermethod
    }
    elsif( $param = $template->macros->{ startIndex } ) {
        if( $query->{ $param } ) {
            $query->{ $param } = $direction eq 'previous'
                ? $query->{ $param } -= $pager->entries_per_page
                : $query->{ $param } += $pager->entries_per_page;
        }
        else {
            $query->{ $param } = $direction eq 'previous'
                ? 1
                : $pager->entries_per_page + 1;
        }
    }

    return $self->parent->do_search( $template->prepare_query( $query ), $method );
}

sub _get_link {
    my $self = shift;
    my $type = shift;
    my $feed = $self->feed->{ atom };
    
    return unless $feed;
    
    for( $feed->link ) {
        return $_->get( 'href' ) if $_->get( 'rel' ) eq $type;
    }

    return;
}

1;
