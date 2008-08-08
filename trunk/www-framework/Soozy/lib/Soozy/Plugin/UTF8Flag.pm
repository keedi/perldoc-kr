package Soozy::Plugin::UTF8Flag;

use strict;
use base qw( Soozy::Plugin );

use Data::Visitor::Encode;


sub dispatcher_output_headers {
    my $self = shift;

    $self->next::method(@_) if $self->stash->{utf8flag_raw_body};

    my $body = $self->res->body;
    if (!ref($body) && utf8::is_utf8($body)) {
        $self->res->content_type('text/html; charset=UTF-8')
            if !$self->res->content_type || $self->res->content_type eq 'text/html';
    }

    $self->next::method(@_);
}

sub dispatcher_output_body {
    my $self = shift;

    $self->next::method(@_) if $self->stash->{utf8flag_raw_body};

    my $body = $self->res->body;
    unless (ref($body)) {
        utf8::encode($body) if utf8::is_utf8($body);
        $self->res->body($body);
    }

    $self->next::method(@_);
}

sub prepare_query_parameters {
    my $self = shift;
    $self->next::method(@_);
    my $param = $self->req->query_parameters;
    my $dev = Data::Visitor::Encode->new;
    $self->req->query_parameters($dev->utf8_on($param));
}

sub prepare_body_parameters {
    my $self = shift;
    $self->next::method(@_);
    my $param = $self->req->body_parameters;
    my $dev = Data::Visitor::Encode->new;
    $self->req->body_parameters($dev->utf8_on($param));
}

1;
