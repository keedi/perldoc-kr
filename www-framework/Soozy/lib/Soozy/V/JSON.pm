package Soozy::V::JSON;

use strict;
use warnings;

use base qw( Soozy::V );

use Encode ();

__PACKAGE__->mk_accessors(qw/ json_dumper /);

sub component {
    my($class, $c) = @_;

    my $self = bless {}, $class;

    my $driver = $self->config->{json_driver} || 'JSON';
    if ($driver eq 'JSON::Syck') {
        JSON::Syck->require or die $@;
        $self->json_dumper(sub { JSON::Syck::Dump($_[0]); });
    } elsif ($driver eq 'JSON') {
        JSON::Converter->require or die $@;
        my $conv = JSON::Converter->new;
        $self->json_dumper(sub {
            my $data = shift;
            ref $data ? $conv->objToJson($data) : $conv->valueToJson($data);
        });
    } else {
        die "Don't know json_driver: $driver";
    }

    return $self;
}

sub process {
    my($self, $c) = @_;

    my $cond = sub { 1 };

    my $data;
    if (my $expose = $self->config->{expose}) {
        if (ref($expose) eq 'Regexp') {
            $cond = sub { $_[0] =~ $expose };
        } elsif (ref($expose) eq 'ARRAY') {
            my %match = map { $_ => 1 } @{ $expose };
            $cond = sub { $match{$_[0]} };
        } elsif(!ref($expose)) {
            $data = $c->stash->{$expose}
        } else {
            $c->log->warn('expose should be an array reference or Regexp object');
        }
    }
    unless (defined $data) {
        $data = +{ map { $cond->($_) ? ( $_ => $c->stash->{$_} ) : () } keys %{ $c->stash } };
    }

    my $callback;
    if ($self->config->{allow_callback}) {
        $callback = $c->req->param( $self->config->{callback_param} || 'callback' );
        die "Invalid callback parameter $callback" unless !$callback || $callback =~ /^[a-zA-Z0-9\.\_\[\]]+$/;
    }

    my $json = $self->json_dumper->($data);
    my $encoding = $self->config->{encoding} || 'utf-8';
    if ( Encode::is_utf8($json) ) {
        $json = Encode::encode($encoding, $json);
    }

    if (($c->req->header_in('User-Agent') || '') =~ /Opera/) {
        $c->content_type("application/x-javascript; charset=$encoding");
    } else {
        $c->content_type("application/json; charset=$encoding");
    }

    if ($callback) {
        $c->contents("$callback($json);");
    } else {
        $c->contents($json);
    }
}

1;

=head1 SYNOPSIS

  # V-JSON.yaml
  default:
    json_driver: JSON::Syck
    allow_callback: 1
    callback_param: cb
    expose: [ json, data]

=head1 SEE ALSO

L<Catalyst::View::JSON>

=cut
