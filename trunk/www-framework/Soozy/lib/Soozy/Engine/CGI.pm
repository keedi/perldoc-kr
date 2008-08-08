package Soozy::Engine::CGI;

use strict;
use warnings;
use base qw( Soozy::Engine );

__PACKAGE__->mk_accessors(qw/env/);

use URI;


sub read_chunk { shift; *STDIN->sysread(@_) }
sub prepare_request {
    my($self, %args) = @_;
    $self->env($args{env}) if $args{env};
}

sub prepare_connection {
    my $self = shift;
    local *ENV = $self->env || \%ENV;

    $self->c->req->address($ENV{REMOTE_ADDR});

    PROXY_CHECK:
    {
        unless ( $self->c->config->{using_frontend_proxy} ) {
            last PROXY_CHECK if $ENV{REMOTE_ADDR} ne '127.0.0.1';
            last PROXY_CHECK if $self->c->config->{ignore_frontend_proxy};
        }
        # in apache httpd.conf (RequestHeader set X-Forwarded-HTTPS %{HTTPS}s)
        $ENV{HTTPS} = $ENV{HTTP_X_FORWARDED_HTTPS} if $ENV{HTTP_X_FORWARDED_HTTPS};
        $ENV{HTTPS} = 'ON' if $ENV{HTTP_X_FORWARDED_PROTO}; # Pound
        last PROXY_CHECK unless $ENV{HTTP_X_FORWARDED_FOR};

        # If we are running as a backend server, the user will always appear
        # as 127.0.0.1. Select the most recent upstream IP (last in the list)
        my($ip) = $ENV{HTTP_X_FORWARDED_FOR} =~ /([^,\s]+)$/;
        $self->c->req->address($ip);
    }

    $self->c->req->hostname($ENV{REMOTE_HOST});
    $self->c->req->protocol($ENV{SERVER_PROTOCOL});
    $self->c->req->user($ENV{REMOTE_USER});
    $self->c->req->method($ENV{REQUEST_METHOD});

    $self->c->req->secure(1) if $ENV{HTTPS} && uc $ENV{HTTPS} eq 'ON';
    $self->c->req->secure(1) if $ENV{SERVER_PORT} == 443;
}

sub prepare_query_parameters {
    my $self = shift;
    local *ENV = $self->env || \%ENV;

    if ($ENV{QUERY_STRING}) {
        $self->SUPER::prepare_query_parameters($ENV{QUERY_STRING});
    }
}

sub prepare_headers {
    my $self = shift;
    local *ENV = $self->env || \%ENV;

    # Read headers from %ENV
    for my $header (keys %ENV) {
        next unless $header =~ /^(?:HTTP|CONTENT|COOKIE)/i;
        (my $field = $header) =~ s/^HTTPS?_//;
        $self->c->req->headers->header($field => $ENV{$header});
    }
}

sub prepare_path {
    my $self = shift;
    local *ENV = $self->env || \%ENV;

    my $scheme = $self->c->req->secure ? 'https' : 'http';
    my $host      = $ENV{HTTP_HOST}   || $ENV{SERVER_NAME};
    my $port      = $ENV{SERVER_PORT} || 80;

    my $base_path;
    if (exists $ENV{REDIRECT_URL}) {
        $base_path = $ENV{REDIRECT_URL};
        $base_path =~ s/$ENV{PATH_INFO}$//;
    } else {
        $base_path = $ENV{SCRIPT_NAME} || '/';
    }

    # If we are running as a backend proxy, get the true hostname
    PROXY_CHECK:
    {
        unless ($self->c->config->{using_frontend_proxy}) {
            last PROXY_CHECK if $host !~ /localhost|127.0.0.1/;
            last PROXY_CHECK if $self->c->config->{ignore_frontend_proxy};
        }
        last PROXY_CHECK unless $ENV{HTTP_X_FORWARDED_HOST};

        $host = $ENV{HTTP_X_FORWARDED_HOST};

        # backend could be on any port, so
        # assume frontend is on the default port
        $port = $self->c->req->secure ? 443 : 80;

        # in apache httpd.conf (RequestHeader set X-Forwarded-Port 8443)
        $port = $ENV{HTTP_X_FORWARDED_PORT} if $ENV{HTTP_X_FORWARDED_PORT};
    }

    my $path = $base_path . ($ENV{PATH_INFO} || '');
    $path =~ s{^/+}{};

    my $uri = URI->new;
    $uri->scheme($scheme);
    $uri->host($host);
    $uri->port($port);
    $uri->path($path);
    $uri->query($ENV{QUERY_STRING}) if $ENV{QUERY_STRING};

    # sanitize the URI
    $uri = $uri->canonical;
    $self->c->req->uri($uri);

    # set the base URI
    # base must end in a slash
    $base_path .= '/' unless $base_path =~ /\/$/;
    my $base = $uri->clone;
    $base->path_query($base_path);
    $self->c->req->base($base);
}

sub dispatcher_output_headers {
    my $self = shift;

    $self->c->res->header(Status => $self->c->res->status);

    $self->write($self->c->res->headers->as_string("\015\012"));
    $self->write("\015\012");
}


sub prepare_write {
    my $self = shift;

    # Set the output handle to autoflush
    *STDOUT->autoflush(1);

    $self->next::method;
}

sub run { shift->handle_request(@_) }

1;


__END__

=head1 NAME

Soozy::Engine::CGI - Web Framework

=head1 COPY FROM

L<Catalyst::Engine::CGI>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut

