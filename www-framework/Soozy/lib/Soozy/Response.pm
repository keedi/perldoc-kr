package Soozy::Response;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

use URI;

__PACKAGE__->mk_accessors(qw/context cookies body headers location status/);

*output = \&body;

sub content_encoding { shift->headers->content_encoding(@_) }
sub content_length   { shift->headers->content_length(@_) }
sub content_type     { shift->headers->content_type(@_) }
sub header           { shift->headers->header(@_) }

sub redirect {
    my $self = shift;

    if (@_) {
        my $location = shift;
        my $status   = shift || 302;

        $self->location($location);
        $self->status($status);
    }

    $self->location;
}

sub redirect_abs {
    my $self = shift;

    if (@_) {
        my $location = shift;

        unless ($location =~ m!^https?://!) {
            my $base = $self->context->req->base;
            my $url = sprintf '%s://%s', $base->scheme, $base->host;
            unless (($base->scheme eq 'http' && $base->port eq '80') ||
                    ($base->scheme eq 'https' && $base->port eq '443')) {
                $url .= ':' . $base->port;
            }
            $url .= $base->path;
            $location = URI->new_abs($location, $url);
        }
        $self->redirect($location, @_);
    }

    $self->location;
}

sub write { shift->context->write(@_); }

1;

__END__

=head1 NAME

Soozy::Response - Web Framework

=head1 COPY FROM

L<Catalyst::Response>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut

