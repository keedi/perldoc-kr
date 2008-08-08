package Soozy::Plugin::Camelize;

use strict;
use warnings;

use base qw( Soozy::Plugin );

use String::CamelCase ();

sub controller_class_name_filter { String::CamelCase::camelize($_[1]) }
sub controller_method_name_filter { 
    my($self, $name) = @_;
    return $name unless $self->config->{method_name_camelize};
    $self->controller_class_name_filter($name);
}

1;
