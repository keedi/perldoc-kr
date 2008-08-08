package Soozy::Plugin::Session::State::Wrapper;

use strict;
use warnings;

use base qw( Soozy::Plugin::Session::State );

__PACKAGE__->mk_accessors(qw( config states ));

use Class::C3;
use UNIVERSAL::require;

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    $self->config($self->c->config->{session}->{state_wrapper});

    $self->states( {} );
    for my $state (@{ $self->config->{states} }) {
        my $pkg  = $state->{state};
        my $name = $pkg;
        unless ($pkg =~ s/^\+//) {
            my $prefix = __PACKAGE__;
            $prefix =~ s/Wrapper$//;
            $pkg = "$prefix$pkg";
        }
        $pkg->require or die $@;
        $self->states->{$name} = $pkg->new($self->c);
    }
    $self->set_state($self->config->{default});

    $self;
}

sub destroy {
    my $self = shift;
    $self->next::method(@_);

    for my $state (keys %{ $self->states }) {
        delete $self->states->{$state};
    }
}

sub set_state {
    my($self, $state) = @_;
    $self->{state} = $self->states->{$state} || $self->states->{$self->config->{default}};
}

sub get_session_id { shift->{state}->get_session_id(@_) }
sub set_session_id { shift->{state}->set_session_id(@_) }

1;
