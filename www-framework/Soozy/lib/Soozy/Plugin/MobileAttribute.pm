package Soozy::Plugin::MobileAttribute;

use strict;
use warnings;

use base qw( Soozy::Plugin );
__PACKAGE__->mk_accessors(qw/ mobile_attribute /);

use HTTP::MobileAttribute;

sub prepare {
    my $self = shift;
    $self->next::method(@_);
    $self->mobile_attribute( HTTP::MobileAttribute->new( $self->req->headers ) );
}

1;
