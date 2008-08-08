package Soozy::Plugin::FillInForm::ForceUTF8;

use strict;
use warnings;

use base qw( Soozy::Plugin::FillInForm );

use HTML::FillInForm::ForceUTF8;

sub dispatcher_output_process {
    my $self = shift;
    $self->next::method;
    return unless $self->{fillinform};

    my $body = $self->engine ? $self->res->body : $self->contents;

    $self->{fillinform}->{scalarref} = \$body;
    my $ret = $self->res->body(HTML::FillInForm::ForceUTF8->new->fill(%{ $self->{fillinform} }));
    $self->res->body($ret) if $self->engine;
    $self->contents($ret);
}

1;

=head1 SEE ALSO

L<HTML::FillInForm::ForceUTF8>

=cut
