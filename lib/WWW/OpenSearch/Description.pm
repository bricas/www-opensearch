package WWW::OpenSearch::Description;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use Carp;
use XML::LibXML;
use WWW::OpenSearch::Url;

my @columns = qw(
    AdultContent Contact   Description      Developer
    Format       Image     LongName         Query
    SampleSearch ShortName SyndicationRight Tags
    Url
);

__PACKAGE__->mk_accessors( qw( version ns ), map { lc } @columns );

=head1 NAME

WWW::OpenSearch::Description - Encapsulate an OpenSearch Description
provided by an A9 OpenSearch compatible engine

=head1 SYNOPSIS
    
    use WWW::OpenSearch;
    
    my $url = "http://bulkfeeds.net/opensearch.xml";
    my $engine = WWW::OpenSearch->new($url);
    my $description = $engine->description;
    
    my $format   = $description->Format;   # or $description->format
    my $longname = $description->LongName; # or $description->longname
    
=head1 DESCRIPTION

WWW::OpenSearch::Description is a module designed to encapsulate an
OpenSearch Description provided by an A9 OpenSearch compatible engine.
See http://opensearch.a9.com/spec/1.1/description/ for details.

=head1 CONSTRUCTOR

=head2 new( [ $xml ] )

Constructs a new instance of WWW::OpenSearch::Description. If scalar
parameter $xml is provided, data will be automatically loaded from it
using load( $xml ).

=head1 METHODS

=head2 load( $xml )

Loads description data by parsing provided argument using XML::LibXML.

=head2 get_best_url( )

Attempts to retrieve the best URL associated with this description, based
on the following content types (from most preferred to least preferred):

=over 4

=item * application/atom+xml

=item * application/rss+xml

=item * text/xml

=back

=head2 get_url_by_type( $type )

Retrieves the first WWW::OpenSearch::URL associated with this description
whose type is equal to $type.

=head1 ACCESSORS

=head2 version( )

=head2 ns( )

=head2 AdultContent( )

=head2 Contact( )

=head2 Description( )

=head2 Developer( )

=head2 Format( )

=head2 Image( )

=head2 LongName( )

=head2 Query( )

=head2 SampleSearch( )

=head2 ShortName( )

=head2 SyndicationRight( )

=head2 Tags( )

=head2 Url( )

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

for( @columns ) {
    no strict 'refs';
    my $col = lc;
    *$_ = \&$col;
}

sub new {
    my $class = shift;
    my $xml   = shift;
    
    my $self  = $class->SUPER::new;
    
    eval{ $self->load( $xml ); } if $xml;
    if( $@ ) {
        croak "Error while parsing Description XML: $@";
    }

    return $self;
}

sub load {
    my $self = shift;
    my $xml  = shift;
    
    my $parser   = XML::LibXML->new;
    my $doc      = $parser->parse_string( $xml );
    my $element  = $doc->documentElement;
    my $nodename = $element->nodeName;

    croak "Node should be OpenSearchDescription: $nodename" if $nodename ne 'OpenSearchDescription';

    my $ns = $element->getNamespace->value;
    my $version;
    if( $ns eq 'http://a9.com/-/spec/opensearch/1.1/' ) {
        $self->ns( $ns );
        $version = '1.1';
    }
    else {
        $version = '1.0';
    }
    $self->version( $version );

    for my $column ( @columns ) {
        my $node = $doc->documentElement->getChildrenByTagName( $column ) or next;
        if( $column eq 'Url' ) {
            if( $version eq '1.0' ) {
                $self->Url( [ WWW::OpenSearch::Url->new( template => $node->string_value, type => 'application/rss+xml' ) ] );
                next;
            }

            my @url;
            for my $urlnode ( $node->get_nodelist ) {
                my $type = $urlnode->getAttributeNode( 'type' )->value;
                my $url  = $urlnode->getAttributeNode( 'template' )->value;
                $url =~ s/\?}/}/g; # optional
                my $method = $urlnode->getAttributeNode( 'method' );
                $method = $method->value if $method;

                # TODO
                # properly handle POST
                for( $urlnode->getChildrenByTagName( 'Param' ) ) {
                    my $join = '&amp;';
                    if( $url =~ /&amp;/ ) {
                        $join = '?';
                    }
                    my $param = $_->getAttributeNode( 'name' )->value;
                    my $value = $_->getAttributeNode( 'value' )->value;
                    $url .= "$join$param=$value";
                }

                push @url, WWW::OpenSearch::Url->new( template => $url, type => $type, method => $method );
            }
            $self->Url( \@url );
        }
        elsif( $version eq '1.1' and $column eq 'Query' ) {
            my $query = ( $node->get_nodelist )[ 0 ];
            next if $query->getAttributeNode( 'role' )->value eq 'example';
            $self->SampleSearch( $query->getAttributeNode( 'searchTerms' )->value );
        }
        elsif( $version eq '1.0' and $column eq 'Format' ) {
            $self->Format( $node->string_value );
            $self->ns( $self->Format );
        }
        else {
            $self->$column( $node->string_value );
        }
    }
}

sub get_best_url {
    my $self = shift;
    
    return $self->get_url_by_type( 'application/atom+xml' )
        || $self->get_url_by_type( 'application/rss+xml' )
        || $self->get_url_by_type( 'text/xml' )
        || $self->url->[ 0 ];
}

sub get_url_by_type {
    my $self = shift;
    my $type = shift;
    
    my $template;
    for( @{ $self->url } ) {
        $template = $_ if $_->type eq $type;
        last;
    };
    
    return $template;
}

1;
