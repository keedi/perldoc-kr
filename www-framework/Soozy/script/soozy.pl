#!/usr/bin/perl -w                                                                                                                                      

use strict;
use File::Spec;
use FindBin;
use Getopt::Long;
use Pod::Usage;

use Soozy::Helper;

my($help, $force) = (0, 0);
my($httpd_root, $httpd) = qw(/usr/local/apache /usr/local/apache/bin/httpd);


GetOptions(
    'help|?'       => \$help,
    'force'        => \$force,
    'httpd-root=s' => \$httpd_root,
    'httpd=s'      => \$httpd,
);

pod2usage(1) if ($help || !$ARGV[0]);

my $h = Soozy::Helper->new({force => $force, httpd_root => $httpd_root, httpd => $httpd});
pod2usage(1) unless $h->install_skelton($ARGV[0]);

1;
__END__


=head1 NAME

catalyst - Bootstrap a Soozy application

=head1 SYNOPSIS

soozy.pl [options] application-name

'soozy.pl' creates a skeleton for a new application, and allows you to
upgrade the skeleton of your old application.

 Options:
   -force      overwrite files
   -help       display this help and exit
   -httpd-root default /usr/local/apache
   -httpd      default /usr/local/apache/bin/httpd

=head1 INSPIRE BY

L<Catalyst>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
