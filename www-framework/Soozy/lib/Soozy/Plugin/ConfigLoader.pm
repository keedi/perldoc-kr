package Soozy::Plugin::ConfigLoader;

use strict;
use base qw( Soozy::Plugin );

use File::Spec;
use Data::Visitor::Callback;
use Hash::Merge;
use UNIVERSAL::require;

sub initialize {
    my($class, @args) = @_;

    my $root = $ENV{$class->envprefix . '_ROOT'};
    $class->config->{root} = $root;

    if (YAML::Syck->require) {
        *_configloader_load = \&configloader_yaml_syck_load;
    } else {
        YAML->require or die $@;
        *_configloader_load = \&configloader_yaml_load;
    }

    my $file = $root ? "$root/config.yaml" : $class->config->{config};
    if ($file && -e $file) {
        my $config = $class->configloader_load($file);
        if ($config) {
            $class->config($config);
            $class->log->debug("default config load... $file");
        }
    }

    my $path = $root ? "$root/config" : $class->config->{config_dir};
    if ($path && -d $path) {
        opendir my $dir, $path or do {
            $class->log->error("$path: $!");
            die "$path: $!";
        };
        while (my $ent = readdir $dir) {
            next if $ent =~ /^\./;
            next unless $ent =~ /^(.+)\.yaml$/;
            my $key = $1;
            my $file = File::Spec->catfile($path, $ent);

            my $config = $class->configloader_load($file);
            next unless $config;

            $class->config({ $key => $config });
            $class->log->debug("config load... $ent");
        }
    }

    if (my $file = $ENV{$class->envprefix . '_SITECONFIG'}) {
        if ($file && -e $file) {
            if (my $config = $class->configloader_load($file)) {
                my $base = $class->config;
                $class->config(Hash::Merge::merge($config, $base));
                $class->log->debug("site config load... $file");
            }
        }
    }


    my %config_cache;
    my $iv = Data::Visitor::Callback->new(
        plain_value => sub {
            return unless defined $_;
	    if (/^__include\((.+)\)__$/) {
                my $file = ( $root ? "$root/config" : $class->config->{config_dir} ) . "/include/$1";
                $config_cache{$file} ||= $class->configloader_load($file);
                $_ = $config_cache{$file};
            }
    });
    $iv->visit($class->config);

    my $v = Data::Visitor::Callback->new(
        plain_value => sub {
            return unless defined $_;
            s{__HOME__}{ $class->path_to('') }e;
            s{__path_to\((.+)\)__}{ $class->path_to(split '/', $1) }e;
    });
    $v->visit($class->config);

    $class->next::method(@args);
}

sub configloader_load {
    my ($class, $path) = @_;

    my $mode = $ENV{$class->envprefix . '_MODE'} || 'default';
    my $config = $class->_configloader_load($path);

    return Hash::Merge::merge($config->{$mode} || {}, $config->{default});
}

sub configloader_yaml_load {
    my ($class, $path) = @_;

    YAML::LoadFile($path);
}

sub configloader_yaml_syck_load {
    my ($class, $path) = @_;

    open my $fh, $path or die $!;
    my $yaml = do { local $/; <$fh> };
    close($fh);

    YAML::Syck::Load($yaml);
}

1;
__END__

=head1 SEE ALSO

L<Catalyst::Plugin::ConfigLoader>

=cut
