#!/usr/local/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

my $debug             = 0;
my $fork              = 0;
my $help              = 0;
my $host              = undef;
my $port              = 13000;
my $root              = "$FindBin::Bin/../";
my $mode              = 'dev';
my $keepalive         = 0;
my $restart           = 0;
my $restart_delay     = 1;
my $restart_regex     = '\.yml$|\.yaml$|\.pm$';
my $restart_directory = undef;

my @argv = @ARGV;

GetOptions(
    'debug|d'             => \$debug,
    'fork'                => \$fork,
    'help|?'              => \$help,
    'host=s'              => \$host,
    'port=s'              => \$port,
    'root=s'              => \$root,
    'mode=s'              => \$mode,
    'keepalive|k'         => \$keepalive,
    'restart|r'           => \$restart,
    'restartdelay|rd=s'   => \$restart_delay,
    'restartregex|rr=s'   => \$restart_regex,
    'restartdirectory=s'  => \$restart_directory,
);

pod2usage(1) if $help;

$ENV{SOOZY_ENGINE}  ||= $restart ? 'HTTP::Restarter' : 'HTTP';
$ENV{SOOZY_DEBUG}   = 1 if $debug;
$ENV{KPW_ROOT} ||= $root;
$ENV{KPW_MODE} ||= $mode;

# This is require instead of use so that the above environment
# variables can be set at runtime.
require Kpw;

Kpw->run( $port, $host, {
    argv              => \@argv,
    'fork'            => $fork,
    keepalive         => $keepalive,
    restart           => $restart,
    restart_delay     => $restart_delay,
    restart_regex     => qr/$restart_regex/,
    restart_directory => $restart_directory,
} );

1;

=head1 NAME

kpw_server.pl - Soozy Testserver

=head1 SYNOPSIS

kpw_server.pl [options]

 Options:
   -d -debug          force debug mode
   -f -fork           handle each request in a new process
                      (defaults to false)
   -? -help           display this help and exits
      -host           host (defaults to all)
   -p -port           port (defaults to 3000)
   -root              server root
   -mode              server runnning mode (defaults to dev)
   -k -keepalive      enable keep-alive connections
   -r -restart        restart when files get modified
                      (defaults to false)
   -rd -restartdelay  delay between file checks
   -rr -restartregex  regex match files that trigger
                      a restart when modified
                      (defaults to '\.yml$|\.yaml$|\.pm$')
   -restartdirectory  the directory to search for
                      modified files
                      (defaults to '../')

=head1 DESCRIPTION

Run a Soozy Testserver for this application.

=head1 COPY FROM

L<Catalyst>

=head1 AUTHOR

Kazuhiro Osawa

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
