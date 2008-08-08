package Soozy::M::DBIC::Schema;

use strict;
use warnings;

use base qw( Soozy::M );

use UNIVERSAL::require;

__PACKAGE__->mk_classdata($_) for qw/composed schema context s/;

sub component {
    my($class, $c) = @_;

    die '->config->{schema_class} must be defined for this model'
        unless $class->config->{schema_class};

    my $schema_class = $class->config->{schema_class};
    $schema_class->require or die $@;

    if (!$class->config->{connect_info}) {
        if ($schema_class->storage && $schema_class->storage->connect_info) {
            $class->config->{connect_info} = $schema_class->storage->connect_info;
        } else {
            die "Either ->config->{connect_info} must be defined for $class"
                  . " or $schema_class must have connect info defined on it"
                  . "Here's what we got:\n";
        }
    }

    $class->schema($schema_class);

    $class->composed($schema_class->compose_namespace($class, $class->config->{additional_base_classes}));
    $class->schema($class->composed->clone);

    $class->schema->storage_type($class->config->{storage_type})
        if $class->config->{storage_type};

    $class->schema->connection(@{ $class->config->{connect_info} });

    for my $moniker ($class->schema->sources) {
        my $componentname = "$class\::$moniker";
        $c->components->{$componentname} = sub {
            return $class->schema->resultset($moniker);
       };
    }

    $class;
}

sub clone { shift->composed->clone(@_); }

sub connect { shift->composed->connect(@_); }

sub storage { shift->schema->storage(@_); }


1;

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schma>, L<DBIx::Class::Schma>

=cut
