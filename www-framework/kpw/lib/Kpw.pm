package Kpw;

use strict;
use warnings;

use Soozy qw(
  -Engine=1 
  -Debug=1 
  DebugScreen 
  ConfigLoader
  ConfigPatch
  Static::Simple
);

our $VERSION = '0.01';

__PACKAGE__->setup;

1;

=head1 NAME

Kpw - Soozy Based Application

=head1 AUTHOR

Jong-jin Lee

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

