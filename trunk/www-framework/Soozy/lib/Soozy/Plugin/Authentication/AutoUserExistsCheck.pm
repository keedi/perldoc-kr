package Soozy::Plugin::Authentication::AutoUserExistsCheck;

use strict;
use warnings;

use base qw( Soozy::Plugin );

sub forward_to {
    my($self, $method, @args) = @_;

    unless ($self->finished || $self->is_local_forward) {
        my $config = $self->Cconfig->{authentication}->{auto_user_exists_check};

        my $method_config = $config;
        unless ($config->{auto}) {
            $method_config = $config->{$self->get_handle_method};
        }

        if ($method_config) {
            unless ($self->user_exists) {
                return $self->forward($method_config->{forward}) if $method_config->{forward};
                return $self->redirect($method_config->{redirect}) if $method_config->{redirect};
            }
        }
    }

    $self->next::method($method, @_);
}


1;
