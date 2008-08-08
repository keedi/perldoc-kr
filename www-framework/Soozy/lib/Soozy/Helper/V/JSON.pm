package Soozy::Helper::V::JSON;

use strict;
use warnings;

sub create_component {
    my($self, $h) = @_;

    $h->create_template('class', $h->{file});
    $h->create_template('config', File::Spec->catfile($h->{config}, $h->{suffix} . '.yaml'));
}

1;

__DATA__

__class__
package [% class %];

use strict;
use warnings;
use base qw( Soozy::V::JSON );

1;

=head1 NAME

[% class %] - Soozy TT View

==head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__config__
default:
---
