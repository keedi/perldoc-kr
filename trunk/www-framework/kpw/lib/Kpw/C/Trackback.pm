package Kpw::C::Trackback;

use strict;
use warnings;
use base qw( Kpw );

sub do_default {
    my $self = shift;

    my $type = $self->path_args->[0];
    return $self->tb_failure unless $type;
    return $self->tb_failure unless $type eq $self->config->{trackback}->{type};

    my $param = $self->req->parameters;

    for (qw/blog_name title url/) {
	return $self->tb_failure unless $param->{$_};
    }

    my $tb = $self->M('KpwDB::Trackback')->find({
	'url' => $param->{url},
						});

    return $self->tb_failure if $tb;

    my $data = {
	code => 'blah',
	type => $type,
	name => $param->{blog_name},
	title => $param->{title},
	url  => $param->{url},
	excerpt => $param->{excerpt} || 'blah',
    };

    $self->M('KpwDB::Trackback')->create($data);

    return $self->tb_success;
	
}

sub tb_failure {
    my $self = shift;

    $self->res->content_type('text/xml');
    $self->res->body(<<END);
<?xml version="1.0" encoding="utf-8"?>
<response>
  <error>1</error>
</response>
END

}

sub tb_success {
    my $self = shift;

    $self->res->content_type('text/xml');
    $self->res->body(<<END);
<?xml version="1.0" encoding="utf-8"?>
<response>
  <error>0</error>
</response>
END
    
}

1;

=head1 NAME

Kpw::C::Trackback - Soozy Component

=head1 SYNOPSIS

See L<Kpw>

=head1 DESCRIPTION

Soozy Component

=head1 AUTHOR

Jong-jin Lee

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
