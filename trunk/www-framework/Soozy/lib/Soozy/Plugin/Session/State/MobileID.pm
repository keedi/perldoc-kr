package Soozy::Plugin::Session::State::MobileID;

use strict;
use warnings;

use base qw( Soozy::Plugin::Session::State );
__PACKAGE__->mk_accessors(qw( config ));

use HTTP::MobileAttribute;
HTTP::MobileAttribute->load_plugins(qw/ IS UserID /);

sub get_session_id {
    my $self = shift;
    my $mha  = $self->c->mobile_attribute;
    return unless $mha->supports_user_id;
    my $user_id = $mha->user_id;
    return unless $user_id;

    return sprintf 'mobileid:%s:%s', $mha->carrier_longname, $user_id;
}

sub set_session_id {}

1;
