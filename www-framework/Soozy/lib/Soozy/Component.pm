package Soozy::Component;

use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);

use Class::C3;

__PACKAGE__->mk_classdata($_) for qw/_config _plugins/;

sub config {
    my $self = shift;
    $self->_config( {} ) unless $self->_config;
    if (@_) {
        my $config = @_ > 1 ? {@_} : $_[0];
        while ( my ( $key, $val ) = each %$config ) {
            $self->_config->{$key} = $val;
        }
    }
    return $self->_config;
}

sub component { shift }

sub process { die 'no process' }

1;
