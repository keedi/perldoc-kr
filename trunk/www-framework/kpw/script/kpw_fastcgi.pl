#!/opt/local/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;

#use lib "$FindBin::Bin/../lib";
use lib glob "$FindBin::Bin/../../*/lib";

my $help = 0;
my ( $listen, $nproc, $pidfile, $manager, $detach, $keep_stderr );

my $debug        = 0;
my $root         = "$FindBin::Bin/../";
my $mode         = 'dev';
my $max_requests = 0;

GetOptions(
    'debug'          => \$debug,
    'help|?'         => \$help,
    'listen|l=s'     => \$listen,
    'nproc|n=i'      => \$nproc,
    'pidfile|p=s'    => \$pidfile,
    'root=s'         => \$root,
    'mode=s'         => \$mode,
    'manager|M=s'    => \$manager,
    'daemon|d'       => \$detach,
    'keeperr|e'      => \$keep_stderr,
    'max-requests=s' => \$max_requests,
);

pod2usage(1) if $help;

$ENV{SOOZY_ENGINE} = 'FastCGI';
$ENV{SOOZY_DEBUG} = 1 if $debug;
$ENV{KPW_ROOT} ||= $root;
$ENV{KPW_MODE} ||= $mode;

require Kpw;

Kpw->run(
    $listen,
    {
        nproc        => $nproc,
        pidfile      => $pidfile,
        manager      => $manager,
        detach       => $detach,
        keep_stderr  => $keep_stderr,
        max_requests => $max_requests,
    }
);

1;

=head1 NAME  

  [% appprefix %]_fastcgi.pl - Soozy FastCGI                                                                                                          

=head1 SYNOPSIS                                                                                                                                           

  [% appprefix %]_fastcgi.pl [options]                                                                                                                     
  Options:                                                                                                                                             
   -? -help      display this help and exits                                                                                                               
   -l -listen    Socket path to listen on                                                                                                                  
                 (defaults to standard input)                                                                                                              
                 can be HOST:PORT, :PORT or a                                                                                                              
                 filesystem path                                                                                                                          
   -n -nproc     specify number of processes to keep                                                                                                      
                 to serve requests (defaults to 1,                                                                                                        
                 requires -listen)                                                                                                                        
   -p -pidfile   specify filename for pid file                                                                                                             
                 (requires -listen)                                                                                                                       
   -d -daemon    daemonize (requires -listen)                                                                                                             
   -M -manager   specify alternate process manager                                                                                                       
                 (FCGI::ProcManager sub-class)                                                                                                        
                 or empty string to disable                                                                                                           
   -e -keeperr   send error messages to STDOUT, not                                                                                                    
                 to the webserver                                                                                                                         
                                                                                                                                                  
=head1 DESCRIPTION

Run a Catalyst application as fastcgi.

=head1 COPYRIGHT

This library is free sofrtware, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
