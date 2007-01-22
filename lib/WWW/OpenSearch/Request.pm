package WWW::OpenSearch::Request;

use strict;
use warnings;

use base qw( HTTP::Request Class::Accessor::Fast );

use HTTP::Request::Common ();
use URI;

__PACKAGE__->mk_accessors( qw( opensearch_url opensearch_params ) );

=head1 NAME

WWW::OpenSearch::Request - Encapsulate an opensearch request

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new( $url, \%params )

=head1 ACCESSORS

=over 4

=item * opensearch_url

=item * opensearch_params

=back

=head1 AUTHOR

=over 4

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Tatsuhiko Miyagawa and Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

sub new {
    my( $class, $os_url, $params ) = @_;

    my( $uri, $post ) = $os_url->prepare_query( $params );

    my $self;
    if( lc $os_url->method eq 'post' ) {
        $self = HTTP::Request::Common::POST( $uri, $post );
        bless $self, $class;
    }
    else {
        $self = $class->SUPER::new( $os_url->method => $uri );
    }

    $self->opensearch_url( $os_url );
    $self->opensearch_params( $params );

    return $self;
}

1;
