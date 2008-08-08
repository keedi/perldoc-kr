package Soozy;

use strict;
use warnings;
use base qw( Soozy::Core );
our $VERSION = '0.4.0';

use Class::C3;

__PACKAGE__->api_version(0.02);

sub import {
    my($class, @args) = @_;

    return unless $class eq 'Soozy';

    my $caller = caller(0);
    unless ($caller->isa('Soozy')) {
        no strict 'refs';
        push @{"$caller\::ISA"}, $class;
    }

    $class->setup_finished(1);
    $class->arguments([ @args ]);
}

1;

__END__

=head1 NAME

Soozy - Apache Handlers Framework

=head1 INSPIRE BY

L<Sledge>, L<Catalyst>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut

