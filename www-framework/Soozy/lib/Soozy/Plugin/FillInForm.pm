package Soozy::Plugin::FillInForm;

use strict;
use warnings;

use base qw( Soozy::Plugin );

use HTML::FillInForm;

sub new {
    my $class = shift;
    my $self = $class->next::method(@_);
    delete $self->{fillinform};
    $self;
}

sub dispatcher_output_process {
    my $self = shift;
    $self->next::method;
    return unless $self->{fillinform};

    my $body = $self->engine ? $self->res->body : $self->contents;

    $self->{fillinform}->{scalarref} = \$body;
    my $ret = HTML::FillInForm->new->fill(%{ $self->{fillinform} });
    $self->res->body($ret) if $self->engine;
    $self->contents($ret);
}

sub fillinform {
    my $self = shift;
    my $fdat = shift || $self->req->param;

    $self->{fillinform} = {
        @_,
        fdat => $fdat,
    };
}

1;

=head1 SEE ALSO

L<HTML::FillInForm>

=cut
