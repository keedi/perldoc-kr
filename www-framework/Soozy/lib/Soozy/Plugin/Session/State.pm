package Soozy::Plugin::Session::State;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw( c ));

sub new {
    my($class, $c) = @_;
    bless {c => $c}, $class;
}

sub destroy {
    my $self = shift;
    delete $self->{c};
}

1;
