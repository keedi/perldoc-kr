package Soozy::Engine;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw/ class context read_position read_length /);

# Stringify to class
use overload '""' => sub { return ref shift }, fallback => 1;

*c = \&context;

use CGI::Simple::Cookie;
use HTTP::Body;
use HTTP::Headers;
use Scalar::Util;
use URI::QueryParam;

use Soozy::Request::Upload;

our $CHUNKSIZE = 4096;


sub prepare_request {}
sub prepare_connection {}
sub prepare_headers {}
sub prepare_path {}
sub prepare_write {}
sub read_chunk {}
sub run {}


sub prepare_query_parameters {
    my($self, $query_string) = @_;

    # replace semi-colons
    $query_string =~ s/;/&/g;

    my $uri = URI->new('', 'http');
    $uri->query($query_string);
    for my $key ( $uri->query_param ) {
        my @vals = $uri->query_param($key);
        $self->c->req->query_parameters->{$key} = @vals > 1 ? [@vals] : $vals[0];
    }
}

sub prepare_cookie {
    my $self = shift;

    if (my $header = $self->c->req->header('Cookie')) {
        $self->c->req->cookies( { CGI::Simple::Cookie->parse($header) } );
    }
}

sub prepare_read {
    my $self = shift;
    $self->read_position(0);
}

sub prepare_parameters {
    my $self = shift;

    # We copy, no references
    for my $name (keys %{ $self->c->req->query_parameters }) {
        my $param = $self->c->req->query_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        $self->c->req->parameters->{$name} = $param;
    }

    # Merge query and body parameters
    for my $name (keys %{ $self->c->req->body_parameters }) {
        my $param = $self->c->req->body_parameters->{$name};
        $param = ref $param eq 'ARRAY' ? [ @{$param} ] : $param;
        if ( my $old_param = $self->c->req->parameters->{$name} ) {
            if ( ref $old_param eq 'ARRAY' ) {
                push @{ $self->c->req->parameters->{$name} },
                  ref $param eq 'ARRAY' ? @$param : $param;
            } else {
                $self->c->req->parameters->{$name} = [ $old_param, $param ];
            }
        } else {
            $self->c->req->parameters->{$name} = $param;
        }
    }
}

sub prepare_body {
    my $self = shift;

    $self->read_length($self->c->req->header('Content-Length') || 0);
    my $type = $self->c->req->header('Content-Type');

    unless ($self->c->req->{_body}) {
        $self->c->req->{_body} = HTTP::Body->new($type, $self->read_length);
        $self->c->req->{_body}->{tmpdir} = $self->c->config->{uploadtmp}
          if exists $self->c->config->{uploadtmp};
    }

    if ($self->read_length > 0) {
        while (my $buffer = $self->read) {
            $self->c->prepare_body_chunk($buffer);
        }

        # paranoia against wrong Content-Length header
        my $remaining = $self->read_length - $self->read_position;
        if ($remaining > 0) {
            $self->finalize_read;
            die "Wrong Content-Length value: " . $self->read_length;
        }
    }
}

sub prepare_body_chunk {
    my($self, $chunk) = @_;
    $self->c->req->{_body}->add($chunk);
}

sub prepare_body_parameters {
    my $self = shift;
    $self->c->req->body_parameters($self->c->req->{_body}->param);
}

sub prepare_uploads {
    my $self = shift;

    my $uploads = $self->c->req->{_body}->upload;
    for my $name (keys %{ $uploads }) {
        my $files = $uploads->{$name};
        $files = ref $files eq 'ARRAY' ? $files : [$files];

        my @uploads;
        for my $upload (@{ $files }) {
            my $u = Soozy::Request::Upload->new;
            $u->headers(HTTP::Headers->new(%{ $upload->{headers} }));
            $u->type($u->headers->content_type);
            $u->tempname($upload->{tempname});
            $u->size($upload->{size});
            $u->filename($upload->{filename});
            push @uploads, $u;
        }
        $self->c->req->uploads->{$name} = @uploads > 1 ? \@uploads : $uploads[0];

        # support access to the filename as a normal param
        my @filenames = map { $_->{filename} } @uploads;
        $self->c->req->parameters->{$name} =  @filenames > 1 ? \@filenames : $filenames[0];
    }
}


sub finalize_read { undef shift->{_prepared_read} }

sub finalize_cookies {
    my $self = shift;

    for my $name (keys %{ $self->c->res->cookies }) {
        my $val = $self->c->res->cookies->{$name};
        my $cookie = (
            Scalar::Util::blessed($val)
            ? $val
            : CGI::Simple::Cookie->new(
                -name    => $name,
                -value   => $val->{value},
                -expires => $val->{expires},
                -domain  => $val->{domain},
                -path    => $val->{path},
                -secure  => $val->{secure} || 0
            )
        );

        $self->c->res->headers->push_header('Set-Cookie' => $cookie->as_string);
    }
}


sub dispatcher_output_headers {}

sub dispatcher_output_body {
    my $self = shift;
    my $body = $self->c->res->body;
    no warnings 'uninitialized';
    if (Scalar::Util::blessed($body) && $body->can('read') or ref($body) eq 'GLOB') {
        while (!eof $body) {
            read $body, my ($buffer), $CHUNKSIZE;
            last unless $self->write($buffer);
        }
        close $body;
    } else {
        $self->write($body);
    }
}

sub read {
    my ($self, $maxlength) = @_;

    unless ($self->{_prepared_read}) {
        $self->prepare_read;
        $self->{_prepared_read} = 1;
    }

    my $remaining = $self->read_length - $self->read_position;
    $maxlength ||= $CHUNKSIZE;

    # Are we done reading?
    if ($remaining <= 0) {
        $self->finalize_read;
        return;
    }

    my $readlen = ($remaining > $maxlength) ? $maxlength : $remaining;
    my $rc = $self->read_chunk(my $buffer, $readlen);
    if (defined $rc) {
        $self->read_position($self->read_position + $rc);
        return $buffer;
    } else {
        die "Unknown error reading input: $!";
    }
}

sub write {
    my($self, $buffer) = @_;

    unless ( $self->{_prepared_write} ) {
        $self->prepare_write;
        $self->{_prepared_write} = 1;
    }

    print STDOUT $buffer unless $self->{_sigpipe};
}

1;

__END__

=head1 NAME

Soozy::Engine - Web Framework

=head1 COPY FROM

L<Catalyst::Engine>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut

