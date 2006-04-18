package WWW::OpenSearch::Url;

use base qw( Class::Accessor::Fast );

use URI;
use URI::Escape;

__PACKAGE__->mk_accessors( qw( type template method macros ) );

sub new {
    my( $class, %options ) = @_;
    
    $options{ method } ||= 'GET';
    $options{ template } = URI->new( $options{ template } );
    
    my $self = $class->SUPER::new( \%options );
    $self->parse_macros;
    return $self;
}

sub parse_macros {
    my $self = shift;
    
    my %query = $self->template->query_form;
    
    my %macros;
    for( keys %query ) {
        if( $query{ $_ } =~ /^{(.+)}$/ ) {
            $macros{ $1 } = $_;
        }
    }
    
    $self->macros( \%macros );
}

sub prepare_query {
    my( $self, $params ) = @_;
    my $url   = $self->template->clone;
    my %query = $url->query_form;
    
    $params->{ startIndex     } ||= 1;
    $params->{ startPage      } ||= 1;
    $params->{ language       } ||= '*';
    $params->{ outputEncoding } ||= 'UTF-8';
    $params->{ inputEncoding  } ||= 'UTF-8';
    
    my $macros = $self->macros;
    for( keys %$macros ) {
        $query{ $macros->{ $_ } } = $params->{ $_ };
    }
    
    $url->query_form( \%query );
    return $url;
}

1;