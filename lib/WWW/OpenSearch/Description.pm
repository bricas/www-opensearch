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