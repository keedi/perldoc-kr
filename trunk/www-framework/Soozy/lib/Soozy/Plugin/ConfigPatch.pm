package Soozy::Plugin::ConfigPatch;

use strict;
use base qw( Soozy::Plugin );

our $TRIGGER_CONFIG_KEY = '__plugin_config_patch';
our $DELIMITER = '/';

sub initialize {
    my($class, @args) = @_;
    $class->next::method(@args);
    return unless $class->debug;

    return unless $class->config->{$TRIGGER_CONFIG_KEY} && ref($class->config->{$TRIGGER_CONFIG_KEY}) eq 'HASH';
    while (my($keys, $config) = each %{ $class->config->{$TRIGGER_CONFIG_KEY} }) {
        my $orig_conf = $class->config;
        my $patched_key;
        for my $key (split $DELIMITER, $keys) {
            $orig_conf = $orig_conf->{$patched_key} if $patched_key;
            $patched_key = $key;
        }
        $orig_conf->{$patched_key} = $config;
    }
}

1;
