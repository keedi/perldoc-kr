package Soozy::V::TT;

use strict;
use warnings;

use base qw( Soozy::V );

use File::Spec;
use Template;
use Storable ();
use UNIVERSAL::require;

sub process {
    my($class, $c) = @_;

    return if $c->engine && $c->res->body;
    return if $c->contents;

    my $config = Storable::dclone($class->config->{OPTIONS});

    my $root = $ENV{$c->envprefix . '_ROOT'};
    $config->{COMPILE_DIR} = File::Spec->catdir($root, 'template', 'tt_cache') unless $config->{COMPILE_DIR};

    my $include_path = File::Spec->catdir($root, 'template', 'tt');
    $config->{INCLUDE_PATH} = [ $include_path ] unless $config->{INCLUDE_PATH};

    if ($config->{PROVIDERS}) {
        my @providers;
        if (ref($config->{PROVIDERS}) eq 'ARRAY') {
            for my $provider (@{ $config->{PROVIDERS} }) {
                my $name   = $provider->{name};
                my $module = 'Template::Provider';
                if ($name eq '_file_') {
                    $provider->{args} = { %{ $config } };
                } else {
                    $module .= "::$name";
                }
                $module->require;
                if ($@) {
                    $c->log->warn("Can't load $module ($@)");
                } else {
                    push @providers, $module->new($provider->{args});
                }
            }
        }
        delete $config->{PROVIDERS};
        $config->{LOAD_TEMPLATES} = \@providers if @providers;
    }

    if (ref($config->{STASH}) eq 'HASH') {
        my $conf   = delete $config->{STASH};
        my $module = 'Template::Stash::' . $conf->{name};
        my $args   = ref($conf->{args}) eq 'HASH' ? $conf->{args} : {};

        $module->require;
        if ($@) {
            $c->log->warn("Can't load $module ($@)");
        } else {
            $config->{STASH} = $module->new($args);
        }
    }

    my $t = Template->new($config) or die 'TT initialize error';

    my $path = lc($c->get_handle_class);
    $path =~ s/\:\:/-/g;
    $path .= '/' . lc($c->get_handle_method) . '.html';

    my $output;
    $t->process($path, { %{ $c->stash }, c => $c }, \$output) or die $t->error();

    if ($c->engine) {
        $c->res->body($output);
        $c->res->content_type('text/html') unless $c->res->content_type;
    } else {
        $c->contents($output);
        $c->content_type('text/html') unless $c->content_type;
    }
}

1;
