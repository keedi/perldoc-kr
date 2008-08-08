package Soozy::Plugin::Plagger;

use strict;
use warnings;
use base qw/ Class::Data::Inheritable Class::Accessor::Fast /;

use Plagger;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata($_) for qw/ __plagger __plagger_results /;

our $__plagger_context;

sub initialize {
    my $c = shift;
    my $ret = $c->next::method(@_);

    $__plagger_context = $c;
    $c->__plagger({});
    $c->__plagger_results({});
    for my $key (keys %{ $c->config->{plagger} }) {
        $c->plagger_register($key, $c->config->{plagger}->{$key});
    }
    $ret;
}

sub destroy {
    my $c = shift;
    my $ret = $c->next::method(@_);

    for my $key (keys %{ $c->__plagger }) {
        $c->__plagger->{$key}->clear_session;
    }
    $c->__plagger_results({});
    $ret;
}

sub plagger_register {
    my($c, $key, $config) = @_;
    my $plagger = Plagger->new(config => $config);
    $c->__plagger->{$key} = $plagger;
}

sub plagger {
    my($c, $key) = @_;
    return unless $c->__plagger->{$key};
    return $c->__plagger->{$key} if $c->__plagger_results->{$key};
    Plagger->set_context($c->__plagger->{$key});
    return ($c->__plagger_results->{$key} = Plagger->context->run);
}

sub plagger_search {
    my($c, $key, $query) = @_;
    Plagger->set_context($c->__plagger->{$key});
    my @feeds = Plagger->context->search($query);
    return unless @feeds;
    return \@feeds;
}


# hack to plagger log methods
{
    package Plagger;

    no warnings 'redefine';
    sub log {
        my($self, $level, $msg, %opt) = @_;
        my $log = $Soozy::Plugin::Plagger::__plagger_context->log;
        return unless $log->can($level);

        my $caller = $opt{caller};
        unless ($caller) {
            my $i = 0;
            while (my $c = caller($i++)) {
                last if $c !~ /Plugin|Rule/;
                $caller = $c;
            }
            $caller ||= caller(0);
        }
        chomp($msg);

        $log->$level("Plagger::$caller $msg");
    }
}

1;
__END__

=head1 NAME

Soozy::Plugin::Plagger - Plagger for Soozy

=head1 SYNOPSIS

    # include it in plugin list
    use Soozy qw/Plagger/;

    # setting
    $c->config->{plagger} = {
        useperl => \'
    plugins:
      - module: Subscription::Config
        config:
          feed:
            - http://use.perl.org/index.rss
        ',
    };

in your controller

    sub do_default {
        my($self, $c) = @_;

        $c->stash->{useperl} = $c->plagger('useperl');
    }

in your template

    <ul>
    [% FOREACH feed = useperl.update.feeds %] # or [% FOREACH feed = c.plagger('useperl').update.feeds %]
        <li>[% feed.title | html %]<br />
            <ul>
            [% FOREACH entry = feed.entries %]
                <li><a href="[% entry.permalink %]">[% entry.title | html %]</a><br />
                    [% entry.body | html %]
                </li>
            [% END %]
            </ul>
        </li>
    [% END %]
    </ul>

=head1 DESCRIPTION

Plagger for Soozy.

=head1 METHODS

=head2 $c->plagger($name);

Returns a ready to use L<Plagger> object.

=head2 $c->plagger_search($name, $query);

Returns a ready to plagger searcher object.

=head2 $c->plagger_register($name, $config);



=head1 SEE ALSO

L<Plagger>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.
