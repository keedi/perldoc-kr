package Soozy::CLI;

use strict;
use warnings;
use base qw( App::CLI App::CLI::Command Soozy::Component );

__PACKAGE__->mk_classdata($_) for qw/ webapp /;

sub c { shift->webapp(@_) }

use UNIVERSAL::require;

sub import {
    my($class, @args) = @_;

    if ($class ne 'Soozy::CLI') {
        my $opts = shift @args;

        my $envprefix;
        $envprefix = $class->webapp->envprefix . '_' if $class->webapp;
        for my $key (keys %{ $opts }) {
            next if $key =~ /^-/;
            $ENV{"$envprefix$key"} = $opts->{$key} unless defined $ENV{"$envprefix$key"};
        }
        return;
    }

    my @app_args;
    my $webapp;
    for my $opt (@args) {
        if ($opt =~ /^-(.+?)=(.+)$/) {
            $webapp = $2 if $1 eq 'WebApp';
        } else {
            push @app_args, $opt;
        }
    }

    my $caller = caller(0);
    if ($webapp) {
        my $webapp_class = "$caller\::WebApp";
        eval qq{
            package $webapp_class;
            use Soozy;
        };
        $@ and die $@;

        $class->soozy_methods_rewrite;

        $class->webapp($webapp_class);
        $class->webapp->setup_finished(1);
        $class->webapp->arguments([ @app_args ]);

        $class->webapp->base_classname($webapp);
        $class->webapp->envprefix(Soozy::Utils::class2env($webapp));
    }

    {
        no strict 'refs';
        push @{"$caller\::ISA"}, $class;
    }
}

sub dispatch {
    my($class, $cli_args, $soozy_args) = @_;

    if ($class->webapp) {
        $class->webapp->setup($soozy_args ? @{ $soozy_args } : ()) if $class->webapp;
        my $c = bless { is_error => 0, stash => {}, forwarded_history => [] }, $class->webapp;
        $class->webapp($c);
    }

    $class->App::CLI::dispatch($cli_args ? @{ $cli_args } : ());
    $class->c->destroy;
}

sub get_cmd {
    my($class, $cmd, @arg) = @_;

    $cmd = 'help' unless $cmd;
    $class->App::CLI::get_cmd($cmd, @arg);
}

sub run_command {
    my $self = shift;

    if ($self->webapp) {
        my $class = ref $self;
        $class =~ s/^$self->{app}:://;
        $class =~ s/::/-/g;
        $self->config($self->webapp->config->{"CLI-$class"});
    }

    $self->App::CLI::Command::run_command(@_);
}

sub soozy_methods_rewrite {
    no warnings 'redefine';

    *{Soozy::Core::setup_components} = sub {
        my $class = shift;
        my $base_class = $class->base_classname;
        Soozy::Component::Loader->load_components($class, search => ["$base_class\::M"]);
    };
}

1;
