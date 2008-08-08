package Soozy::Log;

use strict;
use warnings;

use Data::Dumper;

our %LEVELS = ();

my @levels;
my $i = 0;

__PACKAGE__->import(qw[ debug info warn error fatal ]);

sub import {
    my($class, @import_levels) = @_;

    for my $name (@import_levels) {
        next if $LEVELS{$name};
        my $level = 1 << $i++;
        $LEVELS{$name} = $level;

        no strict 'refs';
        *{$name} = sub {
            my $self = shift;
    
            if ($self->{level} & $level) {
                $self->_log($name, @_);
            }
        };
        push @levels, $name;
    }
}

sub new {
    my($class) = shift;
    my $self = bless {}, $class;
    $self->{level} = 0;
    $self->levels(scalar(@_) ? @_ : keys %LEVELS);
    $self;
}

sub levels {
    my($self, @levels) = @_;
    $self->{level} = 0;
    $self->enable(@levels);
}

sub enable {
    my($self, @levels) = @_;
    $self->{level} |= $_ for map { $LEVELS{$_} } @levels;
}

sub disable {
    my($self, @levels) = @_;
    $self->{level} &= ~$_ for map { $LEVELS{$_} } @levels;
}

sub _dump {
    my $self = shift;
    local $Data::Dumper::Terse = 1;
    $self->_log('info', Dumper( @_ ));
}

sub _log {
    my $self    = shift;
    my $level   = shift;
    my $time    = localtime(time);
    my $message = join("\n", @_);
    my @caller  = caller(1);
    print STDERR sprintf("[%s] [Soozy] [%s] [%s] [%s/%s] %s\n", $time, $$, $level, $caller[0], $caller[2], $message);
}

1;

__END__

=head1 SEE ALSO

L<Catalyst::Log>

=cut
