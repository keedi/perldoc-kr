package Soozy::Request::Apache;

use strict;
use warnings;
use base qw( Soozy::Base );

use Apache;
use Apache::Request;
use URI;

sub new {
    my($class, @args) = @_;
    my $self = $class->next::method(@args);

    unless ($self->req) {
        $self->req( Apache::Request->new( $args[0] || Apache->request) );
        $self->req->param;
    }
    return $self;
}

1;
