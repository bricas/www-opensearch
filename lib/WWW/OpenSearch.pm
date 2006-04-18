package WWW::OpenSearch;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use Carp;
use LWP::UserAgent;
use WWW::OpenSearch::Response;
use WWW::OpenSearch::Description;

__PACKAGE__->mk_accessors( qw( description_url agent description ) );

our $VERSION = '0.06';

sub new {
    my( $class, $url ) = @_;
    
    croak( "No OpenSearch Description url provided" ) unless $url;
    
    my $self = $class->SUPER::new;

    $self->description_url( $url );
    $self->agent( LWP::UserAgent->new( agent => join( '/', ref $self, $VERSION ) ) );

    $self->fetch_description;
    
    return $self;
}

sub fetch_description {
    my( $self, $url ) = @_;
    $url ||= $self->description_url;
    $self->description_url( $url );
    my $response = $self->agent->get( $url );
    
    unless( $response->is_success ) {
        croak "Error while fetching $url: " . $response->status_line;
    }

    $self->description( WWW::OpenSearch::Description->new( $response->content ) );
}

sub search {
    my( $self, $query, $params ) = @_;

    $params ||= { };
    $params->{ searchTerms } = $query;
    
    my $url = $self->description->get_best_url;
    return $self->do_search( $url->prepare_query( $params ), $url->method );
}

sub do_search {
    my( $self, $url, $method ) = @_;
    
    $method = lc( $method ) || 'get';
    
    my $response;
    if( $method eq 'post' ) {
        my %form = $url->query_form;
        $url->query_form( { } );
        $response = $self->agent->post( $url, \%form );
    }
    else {
        $response = $self->agent->$method( $url );
    }
    
    return WWW::OpenSearch::Response->new( $self, $response );    
}

1;