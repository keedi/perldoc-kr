package Soozy::Plugin::Session::Store::DBIC;

use strict;
use warnings;

use base qw( Soozy::Plugin::Session::Store );

__PACKAGE__->mk_accessors(qw( dbic config ));

use Class::C3;
use MIME::Base64;
use Storable;

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    $self->config($self->c->config->{session}->{store_dbic});
    $self->dbic($self->c->M($self->config->{session_schema}));
    $self;
}

sub get_session_data {
    my($self, $key, $want_expires) = @_;

    if ($key =~ /^expires:(.*)$/) {
        return $self->get_session_data("session:$1", 1);
    }

    my $field = $want_expires ? $self->config->{expires_field} : $self->config->{data_field};
    my $session = $self->dbic->find($key, { select => $field });
    return unless $session;

    my $data = $session->get_column($field);
    return unless $data;
    return $data if $want_expires;
    return Storable::thaw(decode_base64($data));
}

sub store_session_data {
    my($self, $key, $data, $setting_expires) = @_;

    if ($key =~ /^expires:(.*)$/) {
        $self->store_session_data("session:$1", $data, 1);
        return;
    }

    my $fields = { $self->config->{id_field} => $key };
    if ($setting_expires) {
        $fields->{$self->config->{expires_field}} = $data;
    } else {
        $fields->{$self->config->{data_field}} = encode_base64(Storable::nfreeze($data));
    }

    $self->dbic->update_or_create($fields);
}

sub delete_session_data {
    my($self, $key) = @_;

    return if $key =~ /^expires:/;
    $self->dbic->search({ $self->config->{id_field} => $key })->delete;
}

1;

=head1 SEE ALSO

L<Catalyst::Plugin::Session::Store::DBIC>

=cut
