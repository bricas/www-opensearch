package WWW::OpenSearch;

use strict;
use vars qw($VERSION);
$VERSION = '0.05';

use Carp;
use Data::Page;
use LWP::UserAgent;
use URI::Escape;
use XML::RSS::LibXML;
use XML::LibXML;

my @Cols = qw(
Url Format ShortName LongName Description Tags Image SampleSearch
Developer Contact SyndicationRight AdultContent Query
);
for my $col (@Cols) {
    no strict 'refs';
    *$col = sub { shift->{$col} };
}

sub new {
    my($class, $url) = @_;
    $url or croak "Usage: WWW::OpenSearch->new(URL)";
    my $self = bless { DescriptionUrl => $url }, $class;
    $self->_init();
    $self->fetch_description($url);
    $self;
}

sub _init {
    my $self = shift;
    $self->{ua} = LWP::UserAgent->new(agent => "WWW::OpenSearch/$VERSION");
    $self->{pager} = Data::Page->new();
    $self->{pager}->current_page(1);
}

sub ua    { shift->{ua} }
sub pager { shift->{pager} }

sub fetch_description {
    my($self, $url) = @_;
    my $response = $self->ua->get($url);
    croak "Error while fetching $url: ". $response->status_line
	unless $response->is_success;
    eval {
	my $data = $self->parse_description($response->content);
	for my $attr (keys %$data) {
	    $self->{$attr} = $data->{$attr};
	}
    };
    if ($@) {
	croak "Error while parsing Description XML: $@";
    }
}

sub version {
    my $self = shift;
    $self->{version} = shift if @_;
    $self->{version};
}

sub parse_description {
    my $self = shift;
    my($xml) = @_;
    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_string($xml);
    my $element  = $doc->documentElement;
    my $nodename = $element->nodeName;
    croak "Node should be OpenSearchDescription: $nodename"
        if $nodename ne "OpenSearchDescription";

    my $ns = $element->getNamespace->value;
    if ($ns eq "http://a9.com/-/spec/opensearch/1.1/") {
        $self->version("1.1");
    } else {
        $self->version("1.0");
    }

    my %data;
    for my $col (@Cols) {
        my $node = $doc->documentElement->getChildrenByTagName($col) or next;
        if ($self->version eq '1.1' && $col eq 'Url') {
            my $urlnode = ($node->get_nodelist)[0];
            my $type = $urlnode->getAttributeNode('type')->value;
            if ($type ne 'application/rss+xml') {
                croak "Url/\@type $type is not supported by this module. It should be application/rss+xml";
            }
            $data{$col} = $urlnode->getAttributeNode('template')->value;
            $data{$col} =~ s/\?}/}/g; # optional
        } elsif ($self->version eq '1.1' && $col eq 'Query') {
            my $thisnode = ($node->get_nodelist)[0];
            next if $thisnode->getAttributeNode('role')->value eq 'example';
            $data{SampleSearch} = $thisnode->getAttributeNode('searchTerms')->value;
        } else {
            $data{$col} = $node->string_value;
        }
    }

    \%data;
}

sub search {
    my($self, $query) = @_;
    my $url = $self->setup_query($query);

    my $response = $self->ua->get($url);
    croak "Error while fetching $url: ", $response->status_line
	unless $response->is_success;

    my $rss;
    eval {
	$rss = XML::RSS::LibXML->new();
	$rss->add_module(
	    prefix => "openSearch",
	    uri => "http://a9.com/-/spec/opensearchrss/1.0/",
	);
	$rss->parse($response->content);
	if (my $page = $rss->channel->{openSearch}) {
	    $self->pager->total_entries($page->{totalResults});
	    # XXX I don't understand how I parse startIndex attr.
	    $self->pager->entries_per_page($page->{itemsPerPage});
	}
    };
    if ($@) {
	croak "Error while parsing RSS feed: $@";
    }
    return $rss;
}

sub setup_query {
    my($self, $query) = @_;
    my $data;
    $data->{searchTerms} = uri_escape($query);
    $data->{count}       = $self->pager->entries_per_page;
    $data->{startIndex}  = $self->pager->first == 0 ? 0 : $self->pager->first - 1;
    $data->{startPage}   = $self->pager->{current_page}; # XXX hack

    my $url = $self->{Url}; # copy
    $url =~ s/{(searchTerms|count|startIndex|startPage)}/$data->{$1}/g;
    $url;
}

1;
__END__

=head1 NAME

WWW::OpenSearch - Search A9 OpenSearch compatible engines

=head1 SYNOPSIS

  use WWW::OpenSearch;

  my $url = "http://bulkfeeds.net/opensearch.xml";
  my $engine = WWW::OpenSearch->new($url);

  my $name = $engine->ShortName;
  my $tags = $engine->Tags;

  my $feed = $engine->search("iPod");
  for my $item (@{$feed->items}) {
      print $item->{description};
  }

  # page through page 2 with 20 items in each page
  # Note that some engines don't allow changing these values
  $engine->pager->entries_per_page(20);
  $engine->pager->current_page(2);
  my $feed = $engine->search("iPod");

=head1 BETA

This module is in beta version, which means its API interface and functionalities may be changed in future releases.

=head1 DESCRIPTION

WWW::OpenSearch is a module to search A9's OpenSearch compatible search engines. See http://opensearch.a9.com/ for details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::LibXML>, L<XML::RSS::LibXML>, L<Data::Page>, L<LWP>

=cut
