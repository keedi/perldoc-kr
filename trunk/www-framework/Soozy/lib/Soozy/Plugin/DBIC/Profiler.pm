package Soozy::Plugin::DBIC::Profiler;

use strict;
use warnings;

use base qw( Soozy::Plugin );

__PACKAGE__->mk_accessors(qw/ __soozy_dbic_querylog /);

use Template;

our $TEMPLATE;

sub prepare {
    my $self = shift;

    while (1) {
        last unless $self->debug;

        $self->__soozy_dbic_querylog( {} );
        for my $component (keys %{ $self->components }) {
            next unless $component->isa('Soozy::M::DBIC::Schema');
            DBIx::Class::QueryLog->use or die $@;
            $component->storage->debug(1);
            my $ql = DBIx::Class::QueryLog->new;
            $component->storage->debugobj($ql);
            $self->__soozy_dbic_querylog->{$component} = $ql;
        }

        last;
    }
    $self->next::method(@_);
}

sub dispatcher_output_headers {
    my $self = shift;

    while (1) {
        last unless $self->debug;
        last unless keys %{ $self->__soozy_dbic_querylog };
        last if $self->res->content_type && $self->res->content_type !~ /html/;
        my $tmpl = Template->new;
        $tmpl->process(\$TEMPLATE, { querylog => $self->__soozy_dbic_querylog }, \my $output);
        my $body = $self->res->body;
        last if ref($body);
        $body .= $output unless $body =~ s!(</body>.*)$!$output$1!im;
        $self->res->body($body);
        last;
    }

    $self->next::method(@_);
}

$TEMPLATE = q{
<div id="sooz_dbic_profiler">
    <h2>Query Log Report</h2>
    [% FOREACH row IN querylog %]
        [% SET log = row.value %]
        [% SET total = log.time_elapsed %]
        <h3>Component Name: [% row.key %]</h3>
        <h3>Total SQL Time: [% total | format('%0.6f') %]</h3>
        <h3>Total Queries : [% log.count %]</h3>
        <table border="1">
            <tr>
                <th>Time</th>
                <th>%</th>
                <th>SQL</th>
            </tr>
            [% FOREACH q = log.get_sorted_queries %]
                <tr>
                    <td>[% q.time_elapsed | format('%0.6f') %]</td>
                    <td>[% (q.time_elapsed / total) * 100 | format('%i') %]</td>
                    <td>[% q.sql | html %]</td>
                </tr>
            [% END %]
        </table>
    [% END %]
</div>
};

1;

