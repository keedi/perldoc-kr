package Kpw::C::Epilogue;

use strict;
use warnings;
use base qw( Kpw );

use Email::Valid;
use Data::Dumper;

sub do_default {
    my $self = shift;
    $self->stash->{form_messages} = shift;

    my $epilogues =
      $self->M('KpwDB::Epilogue')
      ->search( {}, { order_by => 'created_on desc' } );
    $self->stash->{epilogues} = [ $epilogues->all ];

    my $trackbacks =
      $self->M('KpwDB::Trackback')
      ->search( {}, { order_by => 'created_on desc' } );
    $self->stash->{trackbacks} = [ $trackbacks->all ];
}

sub do_do {
    my $self = shift;

    my $param = $self->req->parameters;

    # validation from register.pm
    my $invalid;
    while ( my ( $key, $row ) = each %{$param} ) {
        next unless $key =~ /^(?:email|content)$/;
        unless ($row) {
            $invalid->{$key} = 'NOT_BLANK';
        }
    }
    unless ( Email::Valid->address( $param->{email} ) ) {
        $invalid->{email} = 'EMAIL';
    }

    return $self->forward( 'default', $invalid ) if $invalid;

    my $user =
      $self->M('KpwDB::RegistForm')->find( { 'email' => $param->{email} } );

    $self->log->debug( Dumper $user);

    if ($user) {
        $param->{user_id} = $user->id;
        $param->{name}     ||= $user->name;
        $param->{password} ||= $user->password;
    }
    $self->M('KpwDB::Epilogue')->create($param);

    $self->res->redirect( $self->config->{url} . 'epilogue' );
}

1;

=head1 NAME

Kpw::C::Epilogue - Soozy Component

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
