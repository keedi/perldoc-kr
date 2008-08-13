package Kpw::C::Admin;

use strict;
use warnings;
use base qw( Kpw );

sub do_default {
    my $self = shift;

    my $rs = $self->M('KpwDB::RegistForm')->search;

    $self->stash->{rs} = $stash;
    $self->stash->{user} = shift;
}

sub do_edit {
    my $self = shift;

    my $param = $self->req->parameters;

    my $user = $self->M('KpwDB::RegistForm')->find({
	'no' => $param->{no},
						   });

    $user->confirm($param->{confirm});
    $user->update;
    return $self->forward('default', $user);
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
