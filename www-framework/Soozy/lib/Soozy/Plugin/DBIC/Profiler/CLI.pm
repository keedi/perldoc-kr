package Soozy::Plugin::DBIC::Profiler::CLI;

use strict;
use warnings;

use base qw( Soozy::Plugin );

__PACKAGE__->mk_classdata( '__soozy_dbic_querylog' => {} );

use UNIVERSAL::isa;
use UNIVERSAL::require;

sub setup_components {
    my $class = shift;

    $class->next::method;
    return unless $class->debug;

    for my $component (keys %{ $class->components }) {
        next unless $component->isa('Soozy::M::DBIC::Schema');
        DBIx::Class::QueryLog->use or die $@;
        $component->storage->debug(1);
        my $ql = DBIx::Class::QueryLog->new;
        $component->storage->debugobj($ql);
        $class->__soozy_dbic_querylog->{$component} = $ql;
    }
}

sub destroy {
    my $class = shift;

    my $conf = $class->config->{soozy_dbic_querylog_cli} || {};
    my $fh = \*STDERR;
    if ($conf->{dumppath}) {
        my $mode = $conf->{append} ? '>>' : '>';
        open $fh, $mode, $conf->{dumppath};
    }

    while (1) {
        last unless $class->debug;
        last unless $class->__soozy_dbic_querylog;

        for my $component (keys %{ $class->__soozy_dbic_querylog }) {
            my $log = $class->__soozy_dbic_querylog->{$component};

            my $total = $log->time_elapsed;
            $fh->printf("Component Name: %s\n", $component);
            $fh->printf("Total SQL Time: %0.6f\n", $total);
            $fh->printf("Total Queries : %d\n", $log->count);

            my $i = 0;
             for my $q (@{ $log->get_sorted_queries }) {
                my $time = sprintf('%0.6f', $q->time_elapsed);
                $fh->printf("--------------+------+\n");
                $fh->printf("%04d % 8s | % 4s |\n", $i, $time, sprintf('%i%%', ($q->time_elapsed / $total) * 100) );
                $fh->printf("%s\n", $q->sql);
            }
            $fh->printf("--------------+------+\n");
        }
        last;
    }
    $class->next::method;
}

1;
