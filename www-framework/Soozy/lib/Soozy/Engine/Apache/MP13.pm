package Soozy::Engine::Apache::MP13;

use strict;
use warnings;
use base qw( Soozy::Engine::Apache );

use Apache            ();
use Apache::Constants qw(OK);
use Apache::File      ();

sub dispatcher_output_headers {
    my $self = shift;
    $self->SUPER::dispatcher_output_headers;
    $self->apache->send_http_header;
    return 0;
}

sub ok_constant { Apache::Constants::OK }

1;

__END__

=head1 NAME

Soozy::Engine::Apache::MP13 - Web Framework

=head1 COPY FROM

L<Catalyst::Engine::Apache::MP13>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut

