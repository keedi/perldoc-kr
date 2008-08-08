package Soozy::Plugin::Session::State::Cookie;

use strict;
use warnings;

use base qw( Soozy::Plugin::Session::State );

__PACKAGE__->mk_accessors(qw( config ));

use Class::C3;

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    $self->config($self->c->config->{session}->{state_cookie});
    $self->config->{session_key} ||= 'sid';
    $self->config->{expires} = $self->c->config->{session}->{expires} unless defined($self->config->{expires});
    $self;
}


sub get_session_id {
    my $self = shift;
    my $cookie = $self->c->cookie->{$self->config->{session_key}}; # XXX engine
    $cookie ? $cookie->value : '';
}

sub set_session_id {
    my($self, $sid) = @_;

    return if $sid eq $self->get_session_id;

    my $expires = defined($self->config->{expires}) ? $self->config->{expires} : (2**31) - time() - 120;
    my %cookie_opts = (
        -name    => $self->config->{session_key},
        -value   => $sid,
        -domain  => $self->config->{domain},
        -path    => $self->config->{path} || '/',
    );
    $cookie_opts{'-expires'} = sprintf(time() + $expires) if $expires;;
    my $cookie = CGI::Cookie->new(%cookie_opts);
    $self->c->req->header_out('Set-Cookie' => $cookie->as_string);
}

1;
