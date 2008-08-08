package Soozy::Plugin::FormValidator::Simple;

use strict;
use warnings;

use base qw( Soozy::Plugin );

use Storable;

require FormValidator::Simple;

sub initialize {
    my $self = shift;
    $self->next::method(@_);
    my $class = 'FormValidator::Simple';

    my $config  = $self->config->{validator} || {};
    my $plugins = $config->{plugins} || [];
    $class->import(@{ $plugins });

    $class->set_messages($config->{messages}) if $config->{messages};
    $class->set_option(%{ $config->{options} }) if $config->{options};
    $class->set_message_format($config->{message_format}) if $config->{message_format};
}

sub prepare {
    my $c = shift;
    $c->next::method(@_);
    $c->{validator} = FormValidator::Simple->new;
}

sub form {
    my($c, @args) = @_;

    if (@args) {
        my $form = $args[1] ? [ @args ] : $args[0];
        $c->{validator}->check($c->req, Storable::dclone($form));
    }
    $c->{validator}->results;
}

sub set_invalid_form {
    my $c = shift;
    $c->{validator}->set_invalid(@_);
    $c->{validator}->results;
}

sub form_message_get {
    my($self, $action, $name) = @_;
    $self->form->message->get($action, $name, $self->form->error($name))
        if $self->form->error($name);
}

1;

=head1 SEE ALSO

L<FormValidator::Simple>, L<Catalyst::Plugin::FormValidator::Simple>

=cut
