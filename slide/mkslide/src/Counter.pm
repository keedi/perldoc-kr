package Counter;

use strict;
use warnings;

my $singleton = undef;

sub new {
    my ( $class ) = @_;

    return $singleton if defined $singleton;

    my $self = 0;
    $singleton = bless \$self, $class;

    return $singleton;
}

sub value {
    my $self = shift;
    return $$self;
}

sub increment {
    my $self = shift;
    return ++$$self;
}

1;
