#!/usr/local/bin/perl -w

use strict;
use File::Spec;
use FindBin;
use Getopt::Long;
use Pod::Usage;

use Soozy::Helper;

my $force = 0;
my $help  = 0;

GetOptions(
    'force'    => \$force,
    'help|?'   => \$help
);

pod2usage(1) if ($help || !$ARGV[0]);

my $h = Soozy::Helper->new({ force => $force, root => File::Spec->catfile($FindBin::Bin, '..')});

pod2usage(1) unless $h->install_component('Kpw', @ARGV);

1;
=head1 NAME

kpw_create.pl - Create a new Soozy Component

=head1 SYNOPSIS

kpw_create.pl [options] C name

kpw_create.pl [options] M|V|C name helper [options]

kpw_create.pl [options] M|V|C name :MyApp::Helper::Foo [options]

kpw_create.pl [options] :MyApp::Helper::Foo [options]

  Options:
   -force        overwrite files
   -help         display this help and exits

 Examples:
   kpw_create.pl C Search
   kpw_create.pl V MyTT TT
   kpw_create.pl M MyDB DBIC::Schema Schema::MyDB dbi:SQLite:/tmp/my.db

=head1 INSPIRE BY

L<Catalyst>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
