package Kpw::C::Register;

use strict;
use warnings;
use base qw( Kpw );

sub do_default {
    my $self = shift;

    $self->stash->{form_messages} = shift;
}

sub do_do {
    my $self = shift;

    my $param = $self->req->parameters;
    $self->fillinform($param);

    # FormValidator::Simple 이 이상해서.. 그냥 수동 Validation

    my $invalid;
    while (my ($key, $row) = each %{ $param } ) {
	unless ($row) {
	    $invalid->{$key} = 'NOT_BLANK';
	}
    }

    if ($param->{password} && $param->{password} ne $param->{password_confirm}) {
	$invalid->{diff_password} = 'NOT_CMP';
    }

    if ($param->{email}) {
	my $user = $self->M('KpwDB::RegistForm')->find({
	    'email' => $param->{email},
					   });

	$invalid->{user_exist} = 'USER_EXIST' if $user;
    }

    return $self->forward('default', $invalid) if $invalid;

    
}

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
