package Soozy::Plugin::Session;

use strict;
use warnings;

use base qw( Soozy::Plugin );

use overload ();
use Digest ();
use Object::Signature ();
use UNIVERSAL::require;


__PACKAGE__->mk_accessors(qw(
session_store session_state
session_id session_expires
session session_flash
session_signature session_flash_signatures
));

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);

    my $config = $self->config->{session};
    my $session_store = $config->{store};
    my $session_state = $config->{state};
    unless ($session_store =~ s/^\+//) {
        $session_store = __PACKAGE__ . "::Store::$session_store";
    }
    unless ($session_state =~ s/^\+//) {
        $session_state = __PACKAGE__ . "::State::$session_state";
    }

    $session_store->require or die $@;
    $session_state->require or die $@;

    $self->session_store($session_store->new($self));
    $self->session_state($session_state->new($self));

    return $self;
}

sub destroy {
    my $self = shift;
    $self->next::method(@_);

    $self->session_store->destroy
        if ref($self->session_store) && $self->session_store->can('destroy');
    $self->session_state->destroy
        if ref($self->session_state) && $self->session_state->can('destroy');

    $self->session_store(undef);
    $self->session_state(undef);
}

#get session
sub prepare {
    my $self = shift;
    $self->next::method(@_);

    my $sid = $self->session_state->get_session_id;
    $self->session_id($sid);
    unless ($sid) {
        $sid = $self->session_make_id;
        $self->session_id($sid);
        $self->session({});
        $self->session_flash({});
        $self->session_expires_update;
    } else {
        $self->session_load;
        $self->session_flash_load;
        $self->session_expires_load;
    }
    $self->session_make_signatures;

}

#set session
sub dispatcher_output_headers {
    my $self = shift;

    my $sid = $self->session_id;
    if ($sid) {
        $self->session_state->set_session_id($sid);
        $self->session_save;
        $self->session_flash_save;
        $self->session_expires_save;
    }
    $self->next::method(@_);
}

sub session_load {
    my $self = shift;

    my $sid  = $self->session_id;
    my $data = $self->session_store->get_session_data("session:$sid") || {};
    $self->session($data);
}

sub session_flash_load {
    my $self = shift;

    my $sid  = $self->session_id;
    my $data = $self->session_store->get_session_data("flash:$sid") || {};
    $self->session_flash($data);
}

sub session_expires_load {
    my $self = shift;

    my $sid     = $self->session_id;
    my $expires = $self->session_store->get_session_data("expires:$sid") || 0;
    $self->session_expires($expires);

    if ($expires && $expires < time()) {
        $self->session_delete;
    }

    $self->session_expires_update;
}

sub session_save {
    my $self = shift;

    my $data = $self->session;
    return if $self->session_signature eq Object::Signature::signature($data);
    $data->{__update} = time();

    my $sid = $self->session_id;
    $self->session_store->store_session_data("session:$sid", $data);
}

sub session_flash_save {
    my $self = shift;

    my $data = $self->session_flash;
    my $sign = $self->session_flash_signatures;
    foreach my $key (keys %{ $data }) {
        next unless $sign->{$key};
        next unless $sign->{$key} eq Object::Signature::signature(ref($data->{$key}) ? $data->{$key} : \$data->{$key});
        delete $data->{$key};
    }

    my $sid = $self->session_id;
    if (%{ $data }) {
        $self->session_store->store_session_data("flash:$sid", $data);
    } else {
        $self->session_store->delete_session_data("flash:$sid");
    }
}

sub session_expires_save {
    my $self = shift;

    my $sid     = $self->session_id;
    my $expires = $self->session_expires;

    $self->session_store->store_session_data("expires:$sid", $expires);
}


sub session_delete {
    my $self = shift;

    my $sid = $self->session_id;
    $self->session_store->delete_session_data("session:$sid");
    $self->session_store->delete_session_data("flash:$sid");

    $self->session({});
    $self->session_flash({});
}


sub session_make_signatures {
    my $self = shift;

    $self->session_signature(Object::Signature::signature($self->session));
    $self->session_flash_signatures({
        map { $_ => Object::Signature::signature(
            ref($self->session_flash->{$_}) ? $self->session_flash->{$_} : \$self->session_flash->{$_}
        ) } keys %{ $self->session_flash }
    });
}

sub session_expires_update {
    my $self = shift;

    my $expires = $self->config->{session}->{expires} || 0;
    $expires += time() if $expires;
    $self->session_expires($expires);
}

sub session_make_id {
    my $self = shift;

    my $digest = $self->session_find_digest;
    $digest->add($self->session_hash_seed);
    return $digest->hexdigest;
}

my $session_hash_seed_counter;
sub session_hash_seed {
    join("", ++$session_hash_seed_counter, time, rand, $$, {}, overload::StrVal(shift));
}

my $session_find_digest_usable;
sub session_find_digest () {
    unless ($session_find_digest_usable) {
        foreach my $alg (qw( SHA-1 SHA-256 MD5 )) {
            if (eval { Digest->new($alg) }) {
                $session_find_digest_usable = $alg;
                last;
            }
        }
        die "Could not find a suitable Digest module. Please install "
            . "Digest::SHA1, Digest::SHA, or Digest::MD5"
            unless $session_find_digest_usable;
    }
    Digest->new($session_find_digest_usable);
}

1;
__END__

default:
  session:
    expires: 0 # 0 is not expire                                                                                                                         store: DBIC
    store_dbic:
      session_schema: Schema::Sessions
      id_field: id
      data_field: session_data
      expires_field: expires
    state: Cookie
    state_cookie:
      session_key: sid
#      domain: .example.jp
#      path: /
#      expires: 0 # 0 is not expire

create table sessions {
  id           char(128) not null,
  session_data text,
  expires      int
}

=head1 SEE ALSO

L<Catalyst::Plugin::Session>

=cut
