package WWW::OpenSearch::Response;

use strict;
use warnings;

use base qw( HTTP::Response Class::Accessor::Fast );

use XML::Feed;
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
# handle previous/next page on POST

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
