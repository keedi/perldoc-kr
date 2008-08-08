package Soozy::Utils;

use strict;
use warnings;


sub class2prefix {
    lc(class2suffix(shift));
}

sub class2suffix {
    my $class = shift;
    $class =~ s/\:\:/-/g;
    $class;
}

sub class2env {
    my $class = uc(shift);
    $class =~ s/\:\:/_/g;
    $class;
}

sub class2configname {
    my $class = shift;
    return "$1-" . class2suffix($2) if $class =~ /^.*::([MVC])::(.*)$/;
    return class2suffix($class);
}

sub class2path {
    my $class = shift;
    $class =~ s/\:\:/\//g;
    $class;
}

sub path2class {
    my $class = shift;
    $class =~ s/\//::/g;
    $class;
}

1;
