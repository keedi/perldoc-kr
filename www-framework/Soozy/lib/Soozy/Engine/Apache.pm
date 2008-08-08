package Soozy::Engine::Apache;

use strict;
use warnings;
use base qw( Soozy::Engine );

__PACKAGE__->mk_accessors(qw/apache return/);

use URI;

sub read_chunk { shift->apache->read(@_) }
sub prepare_request { shift->apache(shift) }

sub prepare_connection {
    my $self = shift;

    $self->c->req->address( $self->apache->connection->remote_ip );

    PROXY_CHECK:
    {
        my $headers = $self->apache->headers_in;
        unless ( $self->c->config->{using_frontend_proxy} ) {
            last PROXY_CHECK if $self->c->req->address ne '127.0.0.1';
            last PROXY_CHECK if $self->c->config->{ignore_frontend_proxy};
        }
        last PROXY_CHECK unless $headers->{'X-Forwarded-For'};

        # If we are running as a backend server, the user will always appear
        # as 127.0.0.1. Select the most recent upstream IP (last in the list)
        my($ip) = $headers->{'X-Forwarded-For'} =~ /([^,\s]+)$/;
        $self->c->req->address( $ip );
    }

    $self->c->req->hostname( $self->apache->connection->remote_host );
    $self->c->req->protocol( $self->apache->protocol );
    $self->c->req->user( $self->apache->user );

    $self->c->req->secure(1) if $ENV{HTTPS} && uc $ENV{HTTPS} eq 'ON';
    $self->c->req->secure(1) if $self->apache->get_server_port == 443;
}

sub prepare_query_parameters {
    my $self = shift;

    if (my $query_string = $self->apache->args) {
        $self->SUPER::prepare_query_parameters($query_string);
    }

}

sub prepare_headers {
    my $self = shift;

    $self->c->req->method($self->apache->method);

    if (my %headers = %{ $self->apache->headers_in }) {
        $self->c->req->header(%headers);
    }
}

sub prepare_path {
    my $self = shift;

    my $scheme = $self->c->req->secure ? 'https' : 'http';
    my $host   = $self->apache->hostname || 'localhost';
    my $port   = $self->apache->get_server_port;

    # If we are running as a backend proxy, get the true hostname
    PROXY_CHECK:
    {
        unless ($self->c->config->{using_frontend_proxy}) {
            last PROXY_CHECK if $host !~ /localhost|127.0.0.1/;
            last PROXY_CHECK if $self->c->config->{ignore_frontend_proxy};
        }
        last PROXY_CHECK unless $self->c->req->header('X-Forwarded-Host');

        $host = $self->c->req->header('X-Forwarded-Host');
        # backend could be on any port, so
        # assume frontend is on the default port
        $port = $self->c->req->secure ? 443 : 80;
    }

    my $base_path = '';

    # Are we running in a non-root Location block?
    my $location = $self->apache->location;
    if ($location && $location ne '/') {
        $base_path = $location;
    }

    # Are we an Apache::Registry script? Why anyone would ever want to run
    # this way is beyond me, but we'll support it!
    if ($self->apache->filename && -f $self->apache->filename && -x _) {
        $base_path .= $ENV{SCRIPT_NAME};
    }

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->host($host);
    $uri->port($port);
    $uri->path($self->apache->uri);
    my $query_string = $self->apache->args;
    $uri->query($query_string);

    # sanitize the URI
    $uri = $uri->canonical;
    $self->c->req->uri($uri);

    # set the base URI
    # base must end in a slash
    $base_path .= '/' unless $base_path =~ /\/$/;
    my $base = $uri->clone;
    $base->path_query($base_path);
    $base = $base->canonical;
    $self->c->req->base($base);
}

sub dispatcher_output_body {
    my $self = shift;

    $self->SUPER::dispatcher_output_body;

    # Data sent using $self->apache->print is buffered, so we need
    # to flush it after we are done writing.
    $self->apache->rflush;
}

sub dispatcher_output_headers {
    my $self = shift;

    for my $name ( $self->c->res->headers->header_field_names ) {
        next if $name =~ /^Content-(Length|Type)$/i;
        my @values = $self->c->res->header($name);
        # allow X headers to persist on error
        if ($name =~ /^X-/i) {
            $self->apache->err_headers_out->add($name => $_) for @values;
        } else {
            $self->apache->headers_out->add($name => $_) for @values;
        }
    }

    # persist cookies on error responses
    if ($self->c->res->header('Set-Cookie') && $self->c->res->status >= 400) {
        for my $cookie ($self->c->res->header('Set-Cookie')) {
            $self->apache->err_headers_out->add('Set-Cookie' => $cookie);
        }
    }

    # The trick with Apache is to set the status code in $apache->status but
    # always return the OK constant back to Apache from the handler.
    $self->apache->status($self->c->res->status);
    $self->c->res->status($self->return || $self->ok_constant);

    my $type = $self->c->res->header('Content-Type') || 'text/html';
    $self->apache->content_type($type);

    if (my $length = $self->c->res->content_length) {
        $self->apache->set_content_length($length);
    }

    return 0;
}



sub write {
    my($self, $buffer) = @_;

    unless ($self->apache->connection->aborted) {
        return $self->apache->print($buffer);
    }
    return;
}


1;

__END__

=head1 NAME

Soozy::Engine::Apache - Web Framework

=head1 COPY FROM

L<Catalyst::Engine::Apache>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut

