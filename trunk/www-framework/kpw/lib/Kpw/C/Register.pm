package Kpw::C::Register;

use strict;
use warnings;
use base qw( Kpw );
use Digest::MD5;

use Data::Dumper;
use Kpw::Mail;
use Email::Valid;

sub do_default {
    my $self = shift;
    $self->stash->{form_messages} = shift;

    my @users =
      $self->M('KpwDB::RegistForm')->search( { confirm => { '<>' => 'wait' } },
        { order_by => ['created_on'] } )->all;
    $self->stash->{users} = \@users;

    my @waits =
      $self->M('KpwDB::RegistForm')
      ->search( { confirm => 'wait' }, { order_by => ['created_on'] } )->all;
    $self->stash->{waits} = \@waits;
}

sub do_do {
    my $self = shift;

    my $param = $self->req->parameters;
    $self->fillinform($param);

    # FormValidator::Simple 이 이상해서.. 그냥 수동 Validation

    my $invalid;
    while ( my ( $key, $row ) = each %{$param} ) {
        next if $key =~ /^(?:location|comment)$/;
        unless ($row) {
            $invalid->{$key} = 'NOT_BLANK';
        }
    }

    if (   $param->{password}
        && $param->{password} ne $param->{password_confirm} )
    {
        $invalid->{diff_password} = 'NOT_CMP';
    }

    unless ( Email::Valid->address( $param->{email} ) ) {
        $invalid->{email} = 'EMAIL';
    }

    if ( $param->{email} ) {
        my $user =
          $self->M('KpwDB::RegistForm')
          ->find( { 'email' => $param->{email}, } );

        $invalid->{user_exist} = 'USER_EXIST' if $user;
    }

    return $self->forward( 'default', $invalid ) if $invalid;

    delete $param->{password_confirm};

    $param->{confirm} = 'wait';
    my $digest = Digest::MD5->new;
    $param->{digest} = $digest->add( $param->{email} )->hexdigest;
    $self->M('KpwDB::RegistForm')->create($param);
    $self->stash->{param} = $param;

    # Mail
    Kpw::Mail->send(
        $self,
        {
            stash    => $self->stash,
            template => 'regist.tt',
            from     => $self->config->{mail}->{from},
            to       => $param->{email},
        }
    );
}

sub do_process {
    my $self = shift;

    my $ukey = $self->req->param('ukey');

    my $user = $self->M('KpwDB::RegistForm')->find(
        {
            'digest'  => $ukey,
            'confirm' => 'wait',
        }
    );

    $self->stash->{ukey} = $ukey;
    $self->stash->{user} = $user;

    $self->stash->{count} =
      $self->M('KpwDB::RegistForm')
      ->search( { confirm => { 'in' => [ 'complete', 'reserv' ] } } )->count;
}

sub do_complete {
    my $self = shift;

    my $param = $self->req->parameters;

    return $self->forward('error') unless $param;

    my $user = $self->M('KpwDB::RegistForm')->find(
        {
            'digest'  => $param->{ukey},
            'confirm' => 'wait',
        }
    );

    return $self->forward('error') unless $user;

    $user->confirm('reserv');
    $user->update;

    $self->stash->{user} = $user;
}

sub do_error { }

1;

=head1 NAME

Kpw::C::Register - Soozy Component

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
