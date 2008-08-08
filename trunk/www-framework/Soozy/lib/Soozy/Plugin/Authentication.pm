package Soozy::Plugin::Authentication;

use strict;
use warnings;

use base qw( Soozy::Plugin );


__PACKAGE__->mk_accessors(qw(
authentication_store
authentication_user
));

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);

    my $config = $self->config->{authentication};
    my $store = $config->{store};
    unless ($store =~ s/^\+//) {
        $store = __PACKAGE__ . "::Store::$store";
    }
    $store->require or die $@;
    $self->authentication_store($store->new($self));

    return $self;
}

sub destroy {
    my $self = shift;
    $self->next::method(@_);
    
    $self->authentication_store->destroy
        if ref($self->authentication_store) && $self->authentication_store->can('destroy');

    $self->authentication_store(undef);
}


sub login {
    my($self, $id, $password) = @_;

    my $user = $self->authentication_store->authentication_check($id, $password);
    if ($user) {
        $self->authentication_user($user);
        if ($self->config->{authentication}->{use_session}) {
            $self->session->{__user} = $user;
        }
        return $user;
    } else {
        $self->logout;
        return;
    }
}

sub logout {
    my $self = shift;

    $self->authentication_user( undef );
    if ($self->config->{authentication}->{use_session}) {
        delete $self->session->{__user};
    }
}

sub user {
    my $self = shift;
    $self->authentication_user || $self->session->{__user} || '';
}

sub get_user {
    my $self = shift;    
    return unless $self->user_exists;
    return $self->authentication_store->get_user($self->user);
}

sub user_exists {
    my $self = shift;
    defined($self->authentication_user) || defined($self->session->{__user});
}

1;


__END__

default:
  authentication:
  store: DBIC
  store_dbic:
    user_schema: Soozy::Members
    user_field: id
    password_field: passwd
  use_session: 1

create table members (
  id       char(32) not null,
  passwd   char(32) not null,

  primary key(id)
);
