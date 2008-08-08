package Soozy::Helper::C::Default;

use strict;
use warnings;

sub create_component {
    my($self, $h) = @_;

    $h->create_template('class', $h->{file});

    my $package = lc($h->{package});
    $package =~ s/\:\:/-/g;
    $h->create_dir(File::Spec->catfile($h->{template_tt}, $package));
    my $tt = File::Spec->catfile($h->{template_tt}, $package, 'default.html');
    $h->create_template('tt', $tt);

    $h->create_template('config', File::Spec->catfile($h->{config}, $h->{suffix} . '.yaml'));
}

1;

__DATA__

__class__
package [% class %];

use strict;
use warnings;
use base qw( [% app %] );

sub do_default {
    my $self = shift;
}

1;

=head1 NAME

[% class %] - Soozy Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Soozy Component

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__tt__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
    <head>
        <meta http-equiv="Content-Language" content="en" />
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>[% app %] - [% package %] on Soozy</title>
    </head>
    <body>
        <h1>Hello! [% app %] - [% package %] default</h1>
    </body>
</html>
__config__
default:
---
