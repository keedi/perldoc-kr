package Soozy::Plugin::ConfigLoader::ForceUTF8;

use strict;
use base qw( Soozy::Plugin::ConfigLoader );

use Data::Visitor::Encode;

sub configloader_load {
    my $class = shift;
    my $conf  = $class->next::method(@_);
    my $dev = Data::Visitor::Encode->new;
    $dev->utf8_on($conf);
}

1;
