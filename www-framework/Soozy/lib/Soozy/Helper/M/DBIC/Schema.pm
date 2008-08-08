package Soozy::Helper::M::DBIC::Schema;

use strict;
use warnings;

use File::Find::Rule;
use File::Spec;

use Soozy::Utils;

sub create_component {
    my($self, $h, $schema, @args) = @_;

    $h->{schema} = $schema or die 'Must supply schema class name';

    my $mode = '';
    if ($args[0] && $args[0] =~ /^create=(dynamic|static)$/) {
        $mode = $1;
        shift @args;
    }
    my $relationships = 1;
    if ($args[0] && $args[0] =~ /^relationships=(\d)$/) {
        $relationships = $1;
        shift @args;
    }
    my $components = [];
    if ($args[0] && $args[0] =~ /^components=([^\s]+)$/) {
        $components = [split /,/, $1];
        shift @args;
    }

    if (@args) {
        $h->{schema_connect} = 1;
        my @schema_connect_info = @args;
        for (@schema_connect_info) {
            if (/^\s*[\[\{]/) {
                $_ = eval $_;
            } else {
                $_ = "'$_'";
            }
        }
        $h->{schema_connect_info} = \@schema_connect_info;
    }

    if ($mode eq 'static') {
        my $dir = $h->{lib};

        DBIx::Class::Schema::Loader->use("dump_to_dir:$dir", 'make_schema_at')
            or die "Can't load DBIx::Class::Schema::Loader: $@";

        my @info = @args;
        my $num = 6;
        for (@info) {
            if (/^\s*[\[\{]/) {
                $_ = eval "$_";
                die "syntax error in argument $num: $@" if $@;
            }
            $num++;
        }

        make_schema_at($schema, { relationships => $relationships, components => $components }, \@info);
    }

    for (@{ $h->{schema_connect_info} }) {
        if (ref $_ eq 'HASH') {
            my $hash = $_;
            my $tmp = join ', ', map { "$_: $hash->{$_}" } keys %{ $_ };
            $_ = "{ $tmp }";
        } elsif (ref $_ eq 'ARRAY') {
            my $tmp = join ', ', @{ $_ };
            $_ = "[ $tmp ]";
        }
    }

    $h->create_template('class', $h->{file});
    $h->create_template('config', File::Spec->catfile($h->{config}, $h->{suffix} . '.yaml'));
}

1;

=head1 SEE ALSO

L<Catalyst::Helper::Model::DBIC::Schma>, L<DBIx::Class::Schma>, L<DBIx::Class::Schma::Loader>

=cut

__DATA__


__class__
package [% class %];

use strict;
use warnings;

use base qw( Soozy::M::DBIC::Schema );

1;

=head1 NAME

[% class %] - Soozy DBIC Schema Model

==head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__config__
default:
  schema_class: [% schema %]
[% IF schema_connect -%]
  connect_info:
[% FOR arg = schema_connect_info -%]
    - [% arg %]
[% END %][% END %]
---

