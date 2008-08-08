package Soozy::Core;

use strict;
use warnings;
use base qw( Soozy::Component );

use bytes;
use CGI::Cookie;
use Class::C3;
use File::stat;
use HTTP::Headers;
use Path::Class::Dir ();
use Path::Class::File ();
use Scalar::Util ();
use UNIVERSAL::require;

use Soozy::Component::Loader;
use Soozy::Log;
use Soozy::Utils;
use Soozy::Request;
use Soozy::Response;


__PACKAGE__->mk_classdata($_)
    for qw(
        arguments engine
        components handle_view default_view base_classname
        log
        validate_class charset_class
        api_version setup_finished
        _plugins envprefix
    );
__PACKAGE__->setup_finished(0);

__PACKAGE__->mk_accessors(qw(
   cookie req res ret_code path_args content_type
   _handle_class _handle_method
   forwarded_history is_local_forward
   contents finished prepare_finished
   is_dorunnning is_error is_force
));

require Module::Pluggable::Fast;


*request  = \&req;
*response = \&res;

sub OK { 200 }
sub REDIRECT { 302 }
sub SERVER_ERROR { 500 }

sub debug { 0 }


sub new {
    my($class) = shift;

    my $self = bless { is_error => 0, ret_code => OK, stash => {}, forwarded_history => [] }, $class;
    $self->set_view($class->default_view);

    $self;
}

sub setup {
    my($class, @args) = @_;
    $class->base_classname($class) unless $class->base_classname;

    @args = (@args, @{ $class->arguments }) if $class->arguments;

    my $flags = {};
    for my $arg (@args) {
        if ($arg =~ /^-(\w+)=?(.*)$/) {
            $flags->{ lc $1 } = $2;
        } else {
            push @{ $flags->{plugins} }, $arg;
        }
    }

    $class->setup_log(delete $flags->{log});

    $class->envprefix(Soozy::Utils::class2env($class->base_classname));
    if (delete $flags->{debug} || $ENV{$class->envprefix . '_DEBUG'} || $ENV{SOOZY_DEBUG}) {
        no strict 'refs';
        *{"$class\::debug"} = sub { 1 };
        $class->log->enable('debug');
        $class->log->debug('Debug mode enabled');
    }

    $class->setup_plugins(delete $flags->{plugins});
    $class->setup_engine(delete $flags->{engine});
    $class->setup_request(delete $flags->{request}); # 0.3.x

    my $default_view = delete $flags->{view};
    for my $flag (sort keys %{$flags}) {
        if (my $code = $class->can("setup_$flag")) {
            &$code($class, delete $flags->{$flag});
        } else {
            $class->log->warn(qq/Unknown flag "$flag"/);
        }
    }

    $class->initialize;

    $class->components( {} );
    $class->setup_components;

    $default_view ||= $class->config->{V}->{DEFAULT} || 'TT';
    $class->default_view($default_view);

    $class->setup_finished(1);
}

sub setup_log {
    my($class, $flag) = @_;

    $class->log(Soozy::Log->new(( $flag && $flag !~ /all/) ? split(/,/, $flag) : ())) unless $class->log;
    $class->log->disable('debug');
    $class->log->debug('log started');
}

sub setup_engine {
    my($class, $engine) = @_;
    return unless $engine;

    $engine = $ENV{$class->envprefix . '_ENGINE'} || $ENV{SOOZY_ENGINE} || $engine;
    $engine = "Soozy::Engine::$engine";

    if ($ENV{MOD_PERL}) {
        {
            no strict 'refs';
            *{"$class\::apache"} = sub { shift->engine->apache };
            *handler = sub ($$) { shift->handle_request(@_) };
        }
    }

    $engine->require or die $@;

    for my $meth (qw/ request connection query_parameters headers cookie body_chunk body_parameters read write /) {
        no strict 'refs';
        no warnings 'redefine';
        *{"prepare_$meth"} = sub {
            my $method = "prepare_$meth";
            shift->engine->$method(@_);
        };
    }


    {
        no strict 'refs';
        no warnings 'redefine';
        *dispatcher_output_body = sub { shift->engine->dispatcher_output_body(@_) };
        *cookie = sub { shift->req->cookies(@_) };
        *redirect = sub { shift->res->redirect(@_) };
        *content_type = sub { shift->res->content_type(@_) };
    }

    $class->log->debug("engine start: $engine");
    $class->engine( $engine->new({ class => $class }) );
}

sub _register_plugin {
    my($class, $plugin, $instant) = @_;

    $plugin->require;
    if ($@) {
        $class->log->error(qq{Couldn\'t load plugin "$plugin", $@});
        return;
    }

    $class->_plugins->{$plugin} = 1;
    unless ($instant) {
        no strict 'refs';
        unshift @{"$class\::ISA"}, $plugin;
        $class->log->debug(qq{load plugin "$plugin"});
    }
    return $class;
}

sub setup_plugins {
    my($class, $plugins) = @_;

    $class->_plugins( {} ) unless $class->_plugins;
    $plugins ||= [];
    for my $plugin ( reverse @$plugins ) {
        unless ($plugin =~ s/\A\+//) {
            $plugin = "Soozy::Plugin::$plugin";
        }
        $class->_register_plugin($plugin);
    }
}

sub setup_request {
    my($class, $request) = @_;

    return if $class->api_version eq '0.01';
    return if $class->engine;

    if ($ENV{MOD_PERL}) {
        $class->log->debug('setup_request');
        $class->_register_plugin('Soozy::Request::Apache');
        *handler = sub ($$) { shift->handle_request(@_); };
    }
}

sub setup_component_prepare { 1 }
sub setup_component_loaded { 1 }

sub setup_components {
    my $class = shift;

    Soozy::Component::Loader->load_components($class);
}

sub initialize {}

sub exception {
    my($self, $msg) = @_;

    return if $self->finished;
    die "Error: $msg" unless $self->prepare_finished;
    $self->is_dorunnning(0);
    $self->is_error(1);

    my $output = "Error: $msg";

    if ($self->engine) {
        $self->res->body($output);
        $self->write($output);
    } else {
        $self->contents($output);
        $self->req->header_out('Content-Length' => length($output));
        $self->req->content_type('text/html');
        $self->req->send_http_header;
        $self->req->print($output);
        $self->finished(1);
    }
}


sub prepare {
    my($self, @args) = @_;

    if ($self->engine) {

        $self->req(Soozy::Request->new({
            arguments        => [],
            body_parameters  => {},
            cookies          => {},
            headers          => HTTP::Headers->new,
            parameters       => {},
            query_parameters => {},
            secure           => 0,
            captures         => [],
            uploads          => {},
        }));

        $self->res(Soozy::Response->new({
            body    => '',
            cookies => {},
            headers => HTTP::Headers->new,
            status  => 200,
        }));
        for my $meth(qw/ engine req res /) {
            $self->$meth->{context} = $self;
            Scalar::Util::weaken($self->$meth->{context});
        }
        $self->res->headers->header('X-Framework' => sprintf 'Soozy/%s', $Soozy::VERSION || '');
    }

    $self->prepare_request(@args);
    $self->prepare_connection;
    $self->prepare_query_parameters;
    $self->prepare_headers;
    $self->prepare_cookie;
    $self->prepare_path;

    $self->prepare_body if $self->engine && !$self->config->{parse_on_demand};
}

sub prepare_request {}
sub prepare_connection {}
sub prepare_query_parameters {}
sub prepare_headers {}
sub prepare_after {}

sub prepare_cookie {
    my($self, @args) = @_;
    my $cookie = CGI::Cookie->fetch;
    $self->cookie($cookie || {});
}

sub prepare_path {
    my($self, @args) = @_;

    my $uri;
    if ($self->engine) {
        $self->engine->prepare_path(@args);
        $uri = $self->req->path;
    } else {
        $uri = $self->req->uri;
    }
    my $app_path = $self->config->{app_path} || '/';
    $uri =~ s/^$app_path//;
    my @path = split /\//, $uri;
    $self->path_args([ @path ]);
}

sub prepare_parameters {
    my $self = shift;
    $self->prepare_body_parameters;
    $self->engine->prepare_parameters(@_);
}

sub prepare_body {
    my $self = shift;

    # Do we run for the first time?
    return if defined $self->req->{_body};

    # Initialize on-demand data
    $self->engine->prepare_body(@_);
    $self->prepare_parameters;
    $self->prepare_uploads;
}

sub prepare_uploads {
    my $self = shift;
    $self->engine->prepare_uploads(@_);
}


sub finalize_cookies { shift->engine->finalize_cookies(@_) }


sub dispatcher {
    my($self, @args) = @_;

    eval {
        $self->is_dorunnning(1);
        $self->dispatcher_prepare;
        unless ($self->finished) {
            $self->log->debug('dispatch to ' . $self->get_handle_class . ' -> ' . $self->get_handle_method . ' -> ' . $self->handle_view);
            if ($self->api_version eq '0.01') {
                my $method = 'do_' . $self->get_handle_method;
                $self->$method();
            } else {
                $self->forward($self->get_handle_method);
            }
        }
        $self->dispatcher_output unless $self->finished;
        $self->is_dorunnning(0);
    };
    if ($@ && !$self->is_force) {
        $self->exception($@);
    }
}

sub dispatcher_prepare {}
sub dispatcher_output {
    my($self, @args) = @_;

    if (($self->engine && $self->res->status =~ /^2..$/) || !$self->engine) {
        $self->dispatcher_output_process;
        $self->dispatcher_output_filter;
        $self->dispatcher_output_filter_after;
    }

    $self->res->body($self->contents) if $self->engine && !$self->res->body && $self->contents;
    $self->dispatcher_output_headers; # finalize_headers

    $self->res->body('') if $self->engine && $self->req->method eq 'HEAD';
    $self->dispatcher_output_body; # finalize_body

    $self->finished(1);
}

sub dispatcher_output_process {
    my($self, @args) = @_;

    my $class = $self->handle_view;
    return unless $class;
    $class = $self->components->{$class} if $self->components->{$class};

    my $orig_class = ref($self);
    $self->controller_dispatcher($self->get_handle_class);
    my $ret = $class->process($self);
    $self->controller_dispatcher($orig_class);

    return $ret;
}

sub dispatcher_output_filter {}
sub dispatcher_output_filter_after {}

sub dispatcher_output_headers {
    my($self, @args) = @_;

    if ($self->engine) {
        # Check if we already finalized headers
        return if $self->res->{_finalized_headers};

        # Handle redirects
        if (my $location = $self->res->redirect ) {
            $self->log->debug(qq/Redirecting to "$location"/) if $self->debug;
            $self->res->header( Location => $location );
        }

        # Content-Length
        if ($self->res->body && !$self->res->content_length) {
            # get the length from a filehandle
            if (Scalar::Util::blessed($self->res->body) && $self->res->body->can('read')) {
                if (my $stat = stat $self->res->body) {
                    $self->res->content_length($stat->size);
                } else {
                    $self->log->warn('Serving filehandle without a content-length');
                }
            } else {
                $self->res->content_length(bytes::length($self->res->body));
            }
        }

        # Errors
        if ($self->res->status =~ /^(1\d\d|[23]04)$/) {
            $self->res->headers->remove_header("Content-Length");
            $self->res->body('');
        }

        $self->finalize_cookies;
        $self->engine->dispatcher_output_headers(@_);

        # Done
        $self->res->{_finalized_headers} = 1;
        return;
    }


#    $self->req->content_type('text/html; charset=' . $self->default_charset)
#        unless $self->req->content_type !~ /text\/html/ && $self->default_charset;
    $self->content_type('text/html') unless $self->content_type;
    $self->req->content_type($self->content_type);
    
    $self->req->header_out('Content-Length' => bytes::length($self->contents));
    $self->req->header_out('X-Framework' => sprintf 'Soozy/%s', $Soozy::VERSION || '');

    $self->req->send_http_header;
}

sub dispatcher_output_body {
    my($self, @args) = @_;

    $self->req->print($self->contents);
}

sub finalize {}
sub destroy {}

sub reset_handles {
    my $self = shift;
    $self->set_handle_class( $self->forwarded_history->[0]->{class} );
    $self->set_handle_method( $self->forwarded_history->[0]->{method} );
}

#
# action methods
#

sub get_handle_class  { shift->_handle_class  || 'Default' }
sub get_handle_method { lc(shift->_handle_method) || 'default' }

sub set_handle_class {
    my($self, $class) = @_;

    my $newclass = sprintf "%s::C::%s", $self->base_classname, $class;
    if ($self->components->{$newclass}) {
        $self->_handle_class($class);
        return $newclass;
    } else {
        $self->_handle_class('');
        return;
    } 
}

sub set_handle_method {
    my($self, $method) = @_;

    if ($method && $self->can("do_$method")) {
        $self->_handle_method($method);
        return $method;
    } else {
        $self->_handle_method('');
        return;
    }
}

sub controller_dispatcher {
    my($self, $class) = @_;

    my $to_class;
    if ($class) {
        my $orig_class = $self->get_handle_class;
        $self->set_handle_class($class);
        $to_class = $self->get_handle_class;
        $self->set_handle_class($orig_class);
    } else {
        $self->controller_class;
        $to_class = $self->get_handle_class;
    }
    $class = sprintf '%s::C::%s', $self->base_classname, $to_class;
    die qq{Can\'t load $class} unless $self->components->{$class};
    bless $self, $class;
}

sub controller_class {
    my($self) = @_;

    my @path_args;
    while (defined(my $path = shift @{ $self->path_args })) {
        my $class = $self->controller_class_name_filter($path);

        my $newclass = $self->set_handle_class(join('::', @path_args, $class));
        if ($newclass) {
            push @path_args, $class;
        } else {
            my $args = $self->path_args;
            unshift @{ $args }, $path;
            $self->path_args($args);
            last;
        } 
    }
    $self->set_handle_class(join('::', @path_args)) if @path_args;
}

sub controller_class_name_filter {
    my($self, $name) = @_;
    $name = ucfirst(lc($name));
    $name =~ s/\-(\w)/uc($1)/ge;
    $name =~ s/\_(\w)/'_'.uc($1)/ge;
    $name;
}

sub controller_method {
    my($self) = @_;

    my $path = shift @{ $self->path_args };
    $path = $self->controller_method_name_filter($path);
    unless ($self->set_handle_method($path)) {
        my $path_args = $self->path_args;
        unshift @{ $path_args }, $path if $path;;
        $self->path_args($path_args);
    }
}

sub controller_method_name_filter { shift; shift }




sub handle_request {
    my($class, @args) = @_;

    my $handle = sub {
        my $self = $class->new(@args);
        eval {
            $self->prepare(@args);
            my $new_obj = $self->controller_dispatcher;# class dispatcher
            $self = $new_obj if ref($new_obj);

            $self->prepare_after if $class->api_version eq '0.01';
            $self->prepare_finished(1);
            $self->controller_method;# method dispatcher
            $self->dispatcher;
            $self->finalize unless $self->is_error;
        };

        if ($@ && !$self->is_error) {
            $self->log->error($@);
            $self->exception($@);
        }
        $self->destroy;

        return $self->ret_code;
    };

    my $status = eval { &$handle; };
    $class->log->error($@) if $@;

    return $status;
}


sub plugin {
    my($class, $name, $plugin, @args) = @_;

    $class->_register_plugin($plugin, 1);
    eval { $plugin->import };

    $class->mk_classdata($name);
    my $obj =  eval { $plugin->new(@args) };

    if ($@) {
        die qq/Couldn\'t instantiate instant plugin "$plugin", "$@"/;
    }
    
    $class->log->debug(qq/Initialized instant plugin "$plugin" as "$name"/);
    $class->$name($obj);
}

sub set_view {
    my($prot, $view) = @_;

    return if ($prot->api_version eq '0.01');

    my $class = $prot->base_classname;
    my $default_view = "$class\::V::$view";
    unless ($class->components->{$default_view}) {
        $class->log->error("Can't load view $default_view");
        die "Can't load view $default_view";
    }
    $class->handle_view($default_view);
}

sub _get_component {
    my($class, $name, @args) = @_;

    my $component = $class->components->{$name};
    if (ref($component) eq 'CODE') {
        return $component->(@args);
    }
    return $component;
}

sub M {
    my($class, $name, @args) = @_;
    my $base_class = $class->base_classname;
#    $class->log->debug("$base_class\::M::$name");
    $class->_get_component("$base_class\::M::$name", @args)
}
sub V {
    my($class, $name, @args) = @_;
    my $base_class = $class->base_classname;
    $class->_get_component("$base_class\::V::$name", @args)
}
sub C {
    my($class, $name, @args) = @_;
    $class = ref($class) || $class;
    $class->_get_component("$class\::C::$name", @args)
}

sub forward_to {
    my($self, $method, @args) = @_;
    unless ($self->finished) {
        if ($method =~ /^\*(.+)$/) {
            $method = $1;
        } else {
            $method = "do_$method";
        }
        $self->log->debug("forward to method: $method");
        $self->$method(@args);
    }
}

sub forward {
    my($self, $to, @args) = @_;;

    my($method, $class) = ($to, ref($self));
    my $base_class = $self->base_classname;
    $class =~ s/^$base_class\::C\:://;
    my $from_class = $class;
    if ($to =~ /^(.+)->(.+)$/) {
        ($class, $method) = ($1, $2);
    }

    $self->set_handle_class($class) unless $self->get_handle_class eq $class;
    unless ($from_class eq $class) {
        $self->controller_dispatcher($class);
        $self->log->debug("forward class: $from_class -> $class (" . ref($self) . ')');
    }

    my $now_history = $self->forwarded_history;
    my @history = @{ $now_history };
    unshift @history, { class => $class, method => $method, forward => "$class->$method", is_local_forward => 0 };
    $self->forwarded_history(\@history);

    my $now_local_forward = $self->is_local_forward;
    $self->is_local_forward(0);
    unless ($method =~ /^\*/) {
        $self->set_handle_method($method);
    } else {
        $self->is_local_forward(1);
        $self->forwarded_history->[0]->{is_local_forward} = 1;
        $self->log->debug("local forwarding");
    }

    $self->log->debug("forward method: $method");
    my $ret = $self->forward_to($method, @args);

    $self->set_handle_class($from_class) if $self->is_local_forward;
    unless ($from_class eq $class) {
        $self->controller_dispatcher($from_class);
        $self->log->debug("return forward class: $class (" . ref($self) . ") -> $from_class");
    }
    $self->is_local_forward($now_local_forward);
    $self->forwarded_history($now_history);

    $ret;
}

sub Cconfig {
    my $class = shift;

    $class = ref($class) || $class;
    my $name = Soozy::Utils::class2configname($class);
    return {} unless $name =~ /^C-/;
    return $class->config->{$name} || {};
}

sub stash {
    my $c = shift;
    if (@_) {
        my $stash = @_ > 1 ? { @_ } : $_[0];
        while (my($k, $v) = each %{ $stash }) {
            $c->{stash}->{$k} = $v;
        }
    }
    $c->{stash};
}

sub redirect {
    my($self, $url, $scheme) = @_;
    unless ($self->finished) {
        my $uri = $self->make_absolute_url($url, $scheme);
        $self->req->header_out(Location => $uri->as_string);
        $self->req->status(REDIRECT);
        $self->contents('');
        $self->dispatcher_output_headers;
        #$self->req->send_http_header;
        $self->finished(1);
        $self->ret_code(REDIRECT);
    }
}

sub make_absolute_url {
    my($self, $url, $scheme) = @_;
    URI->new_abs($url, $self->current_url($scheme));
}

sub current_url {
    my($self, $scheme) = @_;
    $scheme ||= $ENV{HTTPS} ? 'https' : 'http';
    my $url = sprintf '%s://%s%s', $scheme, $self->req->header_in('Host'), $self->req->uri;
    $url .= '?' . $self->req->args if $self->req->args;
    $url;
}

sub path_to {
    my($self, @path) = @_;
    my $path = Path::Class::Dir->new($self->config->{root}, @path);
    return $path if -d $path;
    return Path::Class::File->new($self->config->{root}, @path);
}

sub read { shift->engine->read(@_); }

sub write {
    my $self = shift;
    $self->dispatcher_output_headers;
    my $ret = $self->engine->write(@_);
    $self->finished(1);
    return $ret;
}

sub run { shift->engine->run(@_); }

1;

