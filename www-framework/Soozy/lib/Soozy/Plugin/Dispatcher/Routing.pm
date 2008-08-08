package Soozy::Plugin::Dispatcher::Routing;

use strict;
use warnings;

use base qw( Soozy::Plugin );

__PACKAGE__->mk_accessors(qw/ /);

sub initialize {
    my $class = shift;

    Soozy::Plugin::Dispatcher::Routing::Impl->enable(0);
    my $conf = $class->config->{dispatcher_routing};
    return unless $conf;
    return unless $conf->{before} || $conf->{after};
    return unless ref($conf->{before}) eq 'ARRAY' || ref($conf->{after}) eq 'ARRAY';

    $class->log->debug('routing engine enabled');
    Soozy::Plugin::Dispatcher::Routing::Impl->enable(1);
    Soozy::Plugin::Dispatcher::Routing::Impl::initialize($class, $class->config->{dispatcher_routing});

#    $class->log->_dump($class->config->{dispatcher_routing});
}

sub prepare {
    my $self = shift;
    Soozy::Plugin::Dispatcher::Routing::Impl->in_dispatcher(0);
    $self->next::method(@_);
}

sub controller_dispatcher {
    my $self = shift;
    return $self->next::method(@_) unless Soozy::Plugin::Dispatcher::Routing::Impl->enable;
    return unless Soozy::Plugin::Dispatcher::Routing::Impl->in_dispatcher;
    $self->next::method(@_);
}

sub controller_method {
    my $self = shift;
    return $self->next::method(@_) unless Soozy::Plugin::Dispatcher::Routing::Impl->enable;
    return unless Soozy::Plugin::Dispatcher::Routing::Impl->in_dispatcher;
    $self->next::method(@_);
}

sub dispatcher {
    my($self, @args) = @_;

    eval {
        $self->is_dorunnning(1);
        $self->dispatcher_prepare;
        $self->dispatcher_routing unless $self->finished;
        $self->dispatcher_output unless $self->finished;
        $self->is_dorunnning(0);
    };
    if ($@ && !$self->is_force) {
        $self->exception($@);
    }
}


sub dispatcher_routing {
    my $self = shift;
    return $self->next::method(@_) unless Soozy::Plugin::Dispatcher::Routing::Impl->enable;

    Soozy::Plugin::Dispatcher::Routing::Impl->in_dispatcher(1);

    my $mode = '';
    LOOP:
    while (1) {
        BEFORE:
        while (1) {
            last if $mode eq 'DISPATCH';
            my $ret = Soozy::Plugin::Dispatcher::Routing::Impl::match($self, 'before');
            return             if $ret eq 'END';
            next BEFORE        if $ret eq 'BEFORE';
            $mode = 'DISPATCH' if $ret eq 'DISPATCH';
            $mode = 'AFTER'    if $ret eq 'AFTER';
            last BEFORE;
        }

        if ($mode eq 'DISPATCH') {
            $self->controller_dispatcher;
            $self->controller_method;
            return $self->forward($self->get_handle_method);
        } elsif ($mode ne 'AFTER') {
            my $obj = $self->controller_dispatcher;
            unless ($self->get_handle_class eq 'Default') {
                $self->controller_method;
                return $self->forward($self->get_handle_method);
            }
        }

        AFTER:
        while (1) {
            my $ret = Soozy::Plugin::Dispatcher::Routing::Impl::match($self, 'after');
            return             if $ret eq 'END';
            next AFTER         if $ret eq 'AFTER';
            $mode = 'DISPATCH' if $ret eq 'DISPATCH';
            $mode = 'BEFORE'   if $ret eq 'BEFORE';
            last AFTER;
        }
        next LOOP if $mode =~ /^(?:DISPATCH|BEFORE)$/o;

        $self->controller_method;
        return $self->forward($self->get_handle_method);
    }
}

sub dispatcher_routing_cancel {
    Soozy::Plugin::Dispatcher::Routing::Impl->running_cancel(1);
}
sub dispatcher_routing_redirect {
    Soozy::Plugin::Dispatcher::Routing::Impl->redirected(1);
    shift->redirect(@_);
}


package Soozy::Plugin::Dispatcher::Routing::Impl;

use strict;
use warnings;
use base qw( Class::Data::Inheritable );
__PACKAGE__->mk_classdata($_)
    for qw( in_dispatcher enable running_cancel redirected );

sub initialize {
    my($class, $conf) = @_;

    config_compile($class, $conf->{before});
    config_compile($class, $conf->{after});
}

sub config_compile {
    my ($class, $config) = @_;
    return unless $config;

    for my $route (@{ $config }) {
        $route->{slashend} ||= 'auto';
        if ($route->{slashend} =~ /y/i) {
            $route->{slashend} = 'yes';
        } elsif ($route->{slashend} =~ /n/i) {
            $route->{slashend} = 'no';
        } else {
            $route->{slashend} = 'auto';
        }

        my $path = $route->{path};
        $path =~ s!/+!/!g;
        $path =~ s!^\^!!;
        $path =~ s!\$$!!;
        $path =~ s!^/!!;
        $path =~ s!/$!!;

        my @path_compile = map {
            $route->{icase} ? qr/^$_$/i : qr/^$_$/
        } split m!/!, $path;

        delete $route->{path_compile};
        delete $route->{forward_path_compile};
        delete $route->{rear_path_compile};
        if ($route->{path}      =~ /^\^.+[^\$]$/) {
            $route->{forward_path_compile} = \@path_compile;
        } elsif ($route->{path} =~ /^[^\^].+\$$/) {
            $route->{rear_path_compile}    = \@path_compile;
        } else {
            $route->{path_compile}         = \@path_compile;
        }


        $route->{chain_compile} = [];
        for my $target ( @{ $route->{chain} } ) {
            my $compile;
            if ($target =~ /^(?:NEXT|FIRST|LAST|DISPATCH|BEFORE|AFTER|END)$/) {
                $compile = $target;
            } elsif ($target =~ /^\s*([a-zA-Z0-9\:\_\$]+)->([a-zA-Z0-9\:\_\$]+)(?:\(([\s\,\$0-9]+)\))?\s*$/) {
                my($controller, $method, $arg) = ($1, $2, $3 || '');
                my @args;
                if ($arg) {
                    $arg =~ s/\s//g;
                    @args = split /,/, $arg;
                    for (@args) {
                        die "args mismatch: $arg in " . $route->{path} unless /^\$\d+$/;
                    }
                }

                my $type = ($method =~ /^do_/) ? 'dispatch' : 'instance';
                $compile = { method => sub {
                    my($self, $capture) = @_;
                    my $t_ctr = $controller;
                    my $t_mth = $method;
                    my @t_arg = @args;

                    $t_ctr =~ s/\$(\d+)/$capture->[$1 - 1]/eg;
                    $t_mth =~ s/\$(\d+)/$capture->[$1 - 1]/eg;
                    my @opts;
                    for my $v (@t_arg) {
                        $v =~ s/\$(\d+)/$capture->[$1 - 1]/eg;
                        push @opts, $v;
                    }

                    if ($t_mth =~ /^do_(.+)$/) {
                        my $to_method = $1;
                        $self->set_handle_class($t_ctr);
                        $self = $self->controller_dispatcher($t_ctr);
                        $self->set_handle_method($to_method);
                        $self->forward($self->get_handle_method);
                        return 1;
                    } else {
                        $self->forward("$t_ctr->*$t_mth", @opts);
                        return 0;
                    }
                }, type => $type};
            } elsif ($target =~ /^\s*stash\(\s*([a-zA-Z0-9\-_]+)\s*=>\s*\$(\d+)\s*\)\s*$/) {
                my($name, $idx) = ($1, $2);
                $compile = { method => sub {
                    my($self, $capture) = @_;
                    $self->stash->{$name} = $capture->[$idx - 1];
                }, type => 'stash'};
            } else {
                die "chain mismatch: $target in " . $route->{path};
            }
            push @{ $route->{chain_compile} }, $compile;
        }
    }
}


sub match {
    my($self, $hook) = @_;
    my $config = $self->config->{dispatcher_routing}->{$hook} or return '';

    LOOP:
    while (1) {
        for my $route (@{ $config }) {
            $self->log->debug("check[$hook]: " . $route->{path});

            # end slash
            next if $route->{slashend} eq 'yes' && $self->req->path !~ m!/$!;
            next if $route->{slashend} eq 'no' && $self->req->path =~ m!/$!;

            my $method;
            my $path;
            if ($route->{path_compile}) {
                $method = 'match_path';
                $path = $route->{path_compile};
            } elsif ($route->{forward_path_compile}) {
                $method = 'match_forward_path';
                $path = $route->{forward_path_compile};
            } elsif ($route->{rear_path_compile}) {
                $method = 'match_rear_path';
                $path = $route->{rear_path_compile};
            }

            my $ret = do { no strict 'refs'; $method->($self, $route, $path, $self->path_args) };
            $self->log->debug("ret: $ret");
            next LOOP    if $ret eq 'FIRST';
            last LOOP    if $ret eq 'LAST';
            next         if $ret eq 'NEXT';
            return 'END' if $ret eq 'END';
            return $ret;
        }
        last LOOP;
    }
    return '';
}

sub match_path {
    my($self, $route, $path, $path_args) = @_;
    return 'NEXT' unless scalar(@{ $path }) eq scalar(@{ $path_args });
    return 'NEXT' unless my $capture = is_match($path, $path_args);
    return running($self, $route, $capture, []);
}

sub match_forward_path {
    my($self, $route, $path, $path_args) = @_;
    return 'NEXT' unless scalar(@{ $path }) <= scalar(@{ $path_args });

    my $len = scalar(@{ $path });
    my @new_path = @{ $path_args };
    my @new_path_args = splice @new_path, 0, $len;

    return 'NEXT' unless my $capture = is_match($path, \@new_path_args);
    return running($self, $route, $capture, \@new_path);
}

sub match_rear_path {
    my($self, $route, $path, $path_args) = @_;
    return 'NEXT' unless scalar(@{ $path }) <= scalar(@{ $path_args });

    my $len = scalar(@{ $path });
    my @new_path = @{ $path_args };
    my @new_path_args = splice @new_path, ($#new_path - $len + 1), $len;

    return 'NEXT' unless my $capture = is_match($path, \@new_path_args);
    return running($self, $route, $capture, \@new_path);
}

sub is_match {
    my($path, $path_args) = @_;
    my @capture;
    for (my $i = 0;$i < scalar(@{ $path});$i++) {
        return unless my(@cap) = $path_args->[$i] =~ /$path->[$i]/;
        push @capture, @cap if $1;
    }
    return \@capture;
}

sub running {
    my($self, $route, $capture, $new_path_args) = @_;

    # backup and rewrite path_args
    my $tmp_path_args = $self->path_args;
    $self->path_args($new_path_args);

    my $tmp_controller = $self->get_handle_class;
    my $tmp_method     = $self->get_handle_method;

    __PACKAGE__->running_cancel(0);
    __PACKAGE__->redirected(0);

    for my $target (@{ $route->{chain_compile} }) {
        return $target unless ref($target) eq 'HASH';
        if ($target->{type} eq 'dispatch') {
            $target->{method}->($self, $capture);
            return 'END';
        } elsif ($target->{type} =~ /^(?:instance|stash)$/) {
            $target->{method}->($self, $capture);
            return 'END' if __PACKAGE__->redirected;
            last if __PACKAGE__->running_cancel;
        } else {
            die 'route chain type error';
        }
    }

    $self->path_args($tmp_path_args);
    $self->set_handle_class($tmp_controller);
    $self->set_handle_method($tmp_method);

    return 'NEXT';
}


1;

__END__

    $yaml =<<END;
dispatcher_routing:
  before:
    - path: "/(*)/"
      chain: [ stash(seoname=>$1) NEXT ]
    - path: "/"
      chain: [ User->do_list ]
    - path: "/add/"
      chain: [ User->do_add ]

  after:
    - path: "/(.+)/"
      chain: [ User->instance($1) User->do_view ]
    - path: "/(.+)/(edit|delete)/"
      chain: [ User->instance($1) User->do_$2 ]
    - path: "/(.+)/bookmark/"
      chain: [ User->instance($1) User::Bookmark->do_list ]
    - path: "/(.+)/bookmark/add"
      chain: [ User->instance($1) User::Bookmark->do_add ]
    - path: "/(.+)/bookmark/(.+)/"
      chain: [ User->instance($1) User::Bookmark->instance($2) User::Bookmark->do_view ]
    - path: "/(.+)/bookmark/(.+)/(edit|delete)/"
      chain: [ User->instance($1) User::Bookmark->instance($2) User::Bookmark->do_$3 ]

    - path: "/(.+)/"
      chain: [ Entry->instance($1) Entry->do_view ]

    - path: "/(.+)/(.+)"
      chain: [ Entry->instance($1) stash(date => $2) Entry->view_day ]
END

上から順に妥当性チェックが行われる
urlのパターンにマッチしたら、メソッドのリストを順番に呼び出す
引数付きで呼び出されるメソッドはcontroller_dispatcherの段階で実行されて、引数の妥当性チェックが行われる
引数の妥当性が無ければ、その行は使用されない。
引数なしの場合でも->canしてメソッドが無ければ実行されない

/app/http://hoge みたいな特定のパス以降を一つの変数にまとめて入れる


chainの中の配列は、実行したいClass/methodを複数指定できる。
書きの特殊値が入っていた場合には、そのchainの処理をやめて。各動作を行う
NEXT      次のchainへ
FIRST     現在のフェーズの最初のリストから処理をやりなおす
LAST      現在のフェーズの処理を完了する
DISPATCH  デフォルトのdispatch処理を行う
BEFORE    biforeフェーズの最初へ移動する
AFTER     afterフェーズの最初へ移動する
END       dispatch処理を終らせる (記入する必要は無い、何事もなくchainが最後まで処理されたら自動的にENDとなる)

do_を処理したらchainを終了する(END) do_ 以降は処理しない

#dispatch_maps_finishedが真なら順番に呼び出すのをやめる

controller_dispatcher と controller_method を無効化して
dispatcher を上書きして実装する

1.beforeを処理
2.だめなら Soozy::Core::controller_dispatcher に処理を投げる
3.だめならafterを処理
4.だめならSoozy::Core::controller_methodしてから、next::dispatcherに処理を投げる


pathの先頭に^が有ると先頭一致、$が有ると後方一致でマッチング処理を行う

slashend: yes
  PATHの末尾に/が必須
slashend: no
  PATHの末尾に/が合ってはいけない
slashend: auto
  どちらでも良い default


icase: 1 で大文字小文字を同一視する
