package Soozy::Plugin::Sample;

use strict;
use warnings;

use Class::C3;


sub sample {
    my $class = shift;
    $class->log->debug('Sample1: test');
}

sub sample2 {
    my $class = shift;
    $class->log->debug('Sample1: test2',ref $class);
}

sub error {
    my $class = shift;
    $class->log->debug('Sample1: error');
    $class->next::method;
}


1;
