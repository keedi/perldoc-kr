package Soozy::CLI::Help;

use strict;
use warnings;
use base qw( App::CLI::Command::Help );

use Pod::Simple::Text;

sub import {
    my($class, @args) = @_;

    my $caller = caller(0);
    no strict 'refs';
    push @{"$caller\::ISA"}, $class;

    shift @App::CLI::Command::Help::ISA;
    push @App::CLI::Command::Help::ISA, 'Soozy::CLI';
}

sub run {
    my $self = shift;

    return $self->App::CLI::Command::Help::run(@_) if @_;
    if (my $file = $self->_find_index) {
        open my $fh, '<:utf8', $file or die $!;
        my $parser = Pod::Simple::Text->new;
        my $buf;
        $parser->output_string(\$buf);
        $parser->parse_file($fh);

        $buf =~ s/^NAME\s+(.*?)::Help::\S+ - (.+)\s+DESCRIPTION/    $1:/;
        print $self->loc_text($buf);
    }
    return;
}

sub _find_index {
    my $self = shift;

    my $app = $self->app;
    $app =~ s{::}{/}g;
    foreach my $dir (@INC) {
        my $file = "$dir/$app.pm";
        return $file if -f $file;
    }
    return;
}

1;
