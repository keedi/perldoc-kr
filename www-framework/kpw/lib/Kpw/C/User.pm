package Kpw::C::User;

use strict;
use warnings;
use base qw( Kpw );

sub do_default {
    my $self = shift;

    $self->stash->{form_messages} = shift;
}

sub do_confirm {
    my $self = shift;

    my $param = $self->req->parameters;


    my $invalid;
    while(my ($key, $row) = each %{ $param }) {
	$invalid->{$key} = 'NOT_BLANK' unless $row;
    }

    return $self->forward('default', $invalid) if $invalid;

    my $user = $self->M('KpwDB::RegistForm')->find({
	'email' => $param->{email},
	'password' => $param->{password},
						   });
    
    $invalid->{not_exist} = 'NOT_EXIST' unless $user;
    return $self->forward('default', $invalid) if $invalid;

    $self->stash->{user} = $user;
}

1;

=head1 NAME

Kpw::C::User - Soozy Component

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
