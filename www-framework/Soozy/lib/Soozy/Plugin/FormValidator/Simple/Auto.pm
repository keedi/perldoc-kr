package Soozy::Plugin::FormValidator::Simple::Auto;

use strict;
use warnings;

use base qw( Soozy::Plugin );

sub forward_to {
    my($self, $method, @args) = @_;

    unless ($self->finished || $self->is_local_forward) {
        if (my $profile = $self->Cconfig->{validator}->{rules}->{$self->get_handle_method}) {
            $self->form( ref($profile) eq 'ARRAY' ? @$profile : %$profile );
        }

        if (my $messages = $self->Cconfig->{validator}->{messages}) {
            $self->{validator}->set_messages($messages);
        }

        if (my $format = $self->Cconfig->{validator}->{message_formats}->{$self->get_handle_method}) {
            $self->{validator}->set_message_format($format);
        }
    }

    $self->next::method($method, @args);
}

1;

=head1 SEE ALSO

L<FormValidator::Simple>, L<Soozy::Plugin::FormValidator::Simple>

=cut
