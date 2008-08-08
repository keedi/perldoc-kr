# copied from Module::Pluggable::Fast
package Soozy::Component::Loader;

use strict;
use warnings;

use UNIVERSAL::require;
use File::Find ();
use File::Basename;
use File::Spec::Functions qw/splitdir catdir abs2rel/;

use Soozy::Utils;

sub find_components {
    my($class, $pkg, %args) = @_;
    $args{search} ||= ["$pkg\::C", "$pkg\::V", "$pkg\::M"];

    my %components;
    for my $dir ( exists $INC{'blib.pm'} ? grep { /blib/ } @INC : @INC ) {
        for my $searchpath (@{ $args{search} }) {
            my $sp = catdir($dir, split(/::/, $searchpath));
            next unless -e $sp && -d $sp;
            for my $file (_find_packages($sp)) {
                my($name, $directory) = fileparse $file, qr/\.pm/;
                $directory = abs2rel $directory, $sp;
                my $plugin = join '::', splitdir(catdir($searchpath, $directory, $name));
                if ($args{require}) {
                    $plugin->require;
                    my $error = $UNIVERSAL::require::ERROR;
                    die qq/Couldn\'t load "$plugin", "$error"/ if $error;
                }
                $components{$plugin} = _callback($plugin, %args) unless $components{$plugin};
                for my $loaded (_list_packages($plugin)) {
                    $components{$loaded} = _callback($plugin, %args) unless $components{$loaded};
                }
            }
        }
    }
    \%components;
}

sub load_components {
    my($class, $c, %args) = @_;

    my $components = $class->find_components($c->base_classname, %args);
    for my $component (values %{ $components }) {
        my $key = Soozy::Utils::class2configname($component);
        my $config = ($key =~ /^C-/) ? undef : $c->config->{$key};
        next unless $c->setup_component_prepare($component, $config);
        $component->require or die $@;
        $component->config($config) if $config;
        $c->components->{$component} = $component->component($c);
        $c->setup_component_loaded($component, $c->components->{$component});
        $c->log->debug('load components by ' . $component . '/' . $c->components->{$component});
    }
}

sub _callback {
    my($plugin, %args) = @_;
    ($args{callback} && ref($args{callback}) eq 'CODE') ? $args{callback}->($plugin) : $plugin;
}

sub _find_packages {
    my $search = shift;

    my @files = ();
    my $wanted = sub {
        my $path = $File::Find::name;
        return unless $path =~ /\w+\.pm$/;

        # don't include symbolig links pointing into nowhere
        # (e.g. emacs lock-files)
        return if -l $path && !-e $path;
        $path =~ s#^\\./##;
        push @files, $path;
    };
    File::Find::find({ no_chdir => 1, wanted => $wanted }, $search);
    return @files;
}

sub _list_packages {
    my $class = shift;
    $class .= '::' unless $class =~ m!::$!;

    my @classes;
    no strict 'refs';
    for my $subclass ( grep !/^main::$/, grep /::$/, keys %{ $class } ) {
        $subclass =~ s!::$!!;
        next if $subclass =~ /^::/;
        push @classes, "$class$subclass";
        push @classes, _list_packages("$class$subclass");
    }
    return @classes;
}

1;
