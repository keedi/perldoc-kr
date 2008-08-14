package Kpw::C::Admin;

use strict;
use warnings;
use base qw( Kpw );

sub do_default {
    my ( $self, $modified, $invalid ) = @_;

    my @rs =
      $self->M('KpwDB::RegistForm')
      ->search( undef, { order_by => 'created_on' } )->all;

    $self->stash->{rs}            = \@rs;
    $self->stash->{modified}      = $modified;
    $self->stash->{form_messages} = $invalid;
}

sub do_edit {
    my $self = shift;

    my $param = $self->req->parameters;

    my $user = $self->M('KpwDB::RegistForm')->find( { 'no' => $param->{no}, } );

    $user->confirm( $param->{confirm} );
    $user->update;

    return $self->forward( 'default', $user );
}

sub do_do {
    my $self = shift;

    my $param = $self->req->parameters;
    $self->fillinform($param);
    $self->stash->{param} = $param;

    my $invalid;
    if ( $param->{email} ) {
        my $user =
          $self->M('KpwDB::RegistForm')
          ->find( { 'email' => $param->{email}, } );

        $invalid->{user_exist} = 'USER_EXIST' if $user;
    }
    return $self->forward( 'default', undef, $invalid ) if $invalid;

    $self->M('KpwDB::RegistForm')->create($param);
    return $self->res->redirect( $self->config->{url} . 'admin' );
}

1;

=head1 NAME

Kpw::C::Admin - Soozy Component

=head1 SYNOPSIS

See L<Kpw>

=head1 DESCRIPTION

Soozy Component

=head1 AUTHOR

Jong-jin Lee

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
