package WWW::OpenSearch;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Carp;
use Data::Page;
use LWP::UserAgent;
use URI::Escape;
use XML::RSS;
use XML::Simple;

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
	my $data = XML::Simple::XMLin($response->content);
	for my $attr (keys %$data) {
	    next if $attr eq 'xmlns';
	    $self->{$attr} = $data->{$attr};
	}
    };
    if ($@) {
	croak "Error while parsing Description XML: $@";
    }
}

sub search {
    my($self, $query) = @_;
    my $url = $self->setup_query($query);

    my $response = $self->ua->get($url);
    croak "Error while fetching $url: ", $response->status_line
	unless $response->is_success;

    my $rss;
    eval {
	$rss = XML::RSS->new();
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
    $data->{startPage}   = $self->pager->current_page;

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

  my $name = $engine->{ShortName};
  my @tags = $engine->{Tags};

  my $feed = $engine->search("iPod");
  for my $item (@{$feed->items}) {
      print $item->{description};
  }

  # if you want to page through page 2 with 20 items in each page
  # Note that some engine doesn't allow changing these values
  $engine->pager->entries_per_page(20);
  $engine->pager->current_page(2);
  my $feed = $engine->search("iPod");

=head1 BETA

This module is in beta version, which means its API interface and functionalities may be changes in future releases.

=head1 DESCRIPTION

WWW::OpenSearch is a module to search A9's OpenSearch compatible search engines. See http://opensearch.a9.com/ for details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::Simple>, L<XML::RSS>, L<Data::Page>, L<LWP>

=cut
