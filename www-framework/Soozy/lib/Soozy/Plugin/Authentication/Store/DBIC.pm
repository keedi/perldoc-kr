package Soozy::Plugin::Authentication::Store::DBIC;

use strict;
use warnings;

use base qw( Soozy::Plugin::Authentication::Store );

__PACKAGE__->mk_accessors(qw( dbic config ));

use Class::C3;
use MIME::Base64;
use Storable;

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    $self->config($self->c->config->{authentication}->{store_dbic});
    $self->dbic($self->c->M($self->config->{user_schema}));
    $self;
}

sub authentication_check {
    my($self, $id, $password) = @_;

    my $results = $self->dbic->search({ $self->config->{user_field} => $id });
    return unless $results;
    my $result = $results->next;
    return unless $result;

    my $user = $result->get_column($self->config->{user_field});
    return $user unless $self->config->{password_field};
    return unless $result->get_column($self->config->{password_field}) eq $password;

    return $user;
}

sub get_user {
    my($self, $id) = @_;

    $self->dbic->search({ $self->config->{user_field} => $id });
}

1;
