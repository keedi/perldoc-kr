#!/usr/local/bin/perl -w

use strict;
use File::Spec;
use FindBin;
use Getopt::Long;
use Pod::Usage;
use Template;

use Soozy::Helper;

my($help, $genconfig) = (0, 0);
my($user, $group, $port, $servername, $mode) = ((getpwuid($<))[0], (getgrgid($())[0], '12080', 'localhost', 'dev');

GetOptions(
    'help|?'       => \$help,
    'genconfig'    => \$genconfig,
    'user=s'       => \$user,
    'group=s'      => \$group,
    'port=s'       => \$port,
    'servername=s' => \$servername,
    'mode=s'       => \$mode,
);

pod2usage(1) if $help;

my $h = Soozy::Helper->new({root => File::Spec->catfile($FindBin::Bin, '..')});
$h->_set_dirs;
$h->{force} = 1;

my $file   = File::Spec->catfile($h->{script_template}, 'httpd.conf');
my $config = File::Spec->catfile($h->{script}, 'httpd.conf');

if (! -e $config || $genconfig) {

    $ENV{PERL5LIB} .= $ENV{PERL5LIB} ? ':' . $h->{lib} : $h->{lib};

    my $t = Template->new({ ABSOLUTE => 1 });
    my $output;
    $t->process($file, {
        %{ $h },
        mode       => $mode,
        user       => $user, 
        group      => $group,
        port       => $port,
        servername => $servername,
        PERL5LIB   => $ENV{PERL5LIB},
    }, \$output)
        or die qq/Couldn\'t process "$file", / . $t->error();

    $h->create_file($config, $output);
} elsif (!$ARGV[0]) {
    pod2usage(1);
}
exit unless $ARGV[0];

if ($ARGV[0] eq 'start') {
    system("/usr/local/apache/bin/httpd -f $config");
} elsif ($ARGV[0] eq 'restart') {
    system(sprintf "kill -HUP `cat %s/httpd.pid`", $h->{logs});
} elsif ($ARGV[0] eq 'stop') {
    system(sprintf "kill `cat %s/httpd.pid`", $h->{logs});
}

1;
=head1 NAME

kpw_create.pl - Soozy httpd handler

=head1 SYNOPSIS

kpw_httpd.pl [options] (start|restart|stop)

  Options:
   -genconfig    generate to httpd.conf
   -mode         set run mode
   -user         set User
   -group        set Group
   -port         set Port
   -servername   set ServerName
   -help         display this help and exits

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
