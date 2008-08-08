package Soozy::Helper;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use Config;
use Cwd;
use File::Spec;
use File::Path;
use IO::File;
use FindBin;
use Template;
use UNIVERSAL::require;

use Soozy::Utils;

sub set_author {
    shift->{author}  = $ENV{'AUTHOR'} || eval { @{ [ getpwuid($<) ] }[6] } || 'Default Author';
}

sub _set_dirs {
    my $self = shift;

    $self->{script}              = File::Spec->catdir($self->{root}, 'script');
    $self->{script_template}     = File::Spec->catdir($self->{root}, 'script', 'template');
    $self->{lib}                 = File::Spec->catdir($self->{root}, 'lib');
    $self->{html}                = File::Spec->catdir($self->{root}, 'html');
    $self->{config}              = File::Spec->catdir($self->{root}, 'config');
    $self->{logs}                = File::Spec->catdir($self->{root}, 'logs');
    $self->{t}                   = File::Spec->catdir($self->{root}, 't');
    $self->{template}            = File::Spec->catdir($self->{root}, 'template');
    $self->{template_tt}         = File::Spec->catdir($self->{root}, 'template', 'tt');
    $self->{template_tt_cache}   = File::Spec->catdir($self->{root}, 'template', 'tt_cache');
}

sub install_skelton {
    my($self, $name) = @_;

    return unless $name;

    $self->set_author;

    $self->{env}    = Soozy::Utils::class2env($name);
    $self->{prefix} = Soozy::Utils::class2prefix($name);

    $self->{package} = $name;
    $self->{package_suffix} = Soozy::Utils::class2suffix($name);
    $self->{shebang} = "#!$Config{perlpath} -w";
    $self->{root}    = File::Spec->catdir(Cwd::getcwd, $self->{prefix});

    $self->_set_dirs;

    my @packages = split(/\:\:/, $self->{package});
    $self->{lib_module_pm} = File::Spec->catdir('lib', @packages);
    $self->{module}        = File::Spec->catdir($self->{lib}, @packages);
    $self->{module_pm}     = $self->{module} . '.pm';

    $self->{m} = File::Spec->catdir($self->{module}, 'M');
    $self->{v} = File::Spec->catdir($self->{module}, 'V');
    $self->{c} = File::Spec->catdir($self->{module}, 'C');


    $self->_create_dirs;
    $self->_create_files;
    $self->_create_scripts;

    {
        my $package = $self->{package};
        local $self->{package};
        $self->install_component($package, 'C', 'Default');
        $self->install_component($package, 'V', 'TT', 'TT');
    }

    return $self->{root};
}

sub install_component {
    my($self, $app) = (shift, shift);

    return unless $app;

    $self->_set_dirs;

    $self->set_author;
    $self->{app} = $app;
    $self->{base} ||= File::Spec->catdir($FindBin::Bin, '..');

    $self->{type} = shift;
    if ($self->{type} =~ /^[MVC]$/) {
        $self->{package} = shift;
        $self->{helper}  = shift;

        my $dir = $self->{lib};
        $dir = File::Spec->catdir($dir, Soozy::Utils::class2path($app), $self->{type});
        my $file = $self->{package};

        $self->{class}  = sprintf '%s::%s::%s', $self->{app}, $self->{type}, $self->{package};
        $self->{suffix} = Soozy::Utils::class2suffix(sprintf '%s::%s', $self->{type}, $self->{package});

        if ($file =~ /\:/) {
            my @path = split /\:\:/, $file;
            $file = pop @path;
            $dir = File::Spec->catdir($dir, @path);
        }
        $self->create_dir($dir);
        $self->{file} = File::Spec->catfile($dir, "$file.pm");

        $self->{helper} = 'Default' if $self->{type} eq 'C' && !$self->{helper};
        if ($self->{helper}) {
            my $helper = $self->{helper} =~ /^\:(.+)$/ ? $1 : 'Soozy::Helper::' . $self->{type} . '::' . $self->{helper};
            $helper->require or die $@;

            if ($helper->can('create_component')) {
                $helper->create_component($self, @_);
            }
        }
    } else {
        my $helper = shift;

        $helper = $helper =~ /^\:(.+)$/ ? $1 : "Soozy::Helper::$helper";
        $helper->require or die $@;

        if ($helper->can('create_stuff')) {
            $helper->create_stuff($self, @_);
        }
    }

    return 1;
}


sub _create_dirs {
    my $self = shift;

    $self->create_dir($self->{root});
    $self->create_dir($self->{script});
    $self->create_dir($self->{script_template});
    $self->create_dir($self->{lib});
    $self->create_dir($self->{html});
    $self->create_dir($self->{logs});
    $self->create_dir($self->{config});
    $self->create_dir($self->{t});
    $self->create_dir($self->{template});
    $self->create_dir($self->{template_tt});
    $self->create_dir($self->{template_tt_cache});
    $self->create_dir($self->{module});
    $self->create_dir($self->{m});
    $self->create_dir($self->{v});
    $self->create_dir($self->{c});
}

sub _create_files {
    my $self = shift;

    $self->create_template('config', File::Spec->catfile($self->{root}, 'config.yaml'));
    $self->create_template('packageclass', $self->{module_pm});

    my $time = localtime time;
    $self->create_template('changes', File::Spec->catfile($self->{root}, 'Changes'), { time => $time});
    $self->create_template('makefile', File::Spec->catfile($self->{root}, 'Makefile.PL'));

    $self->create_template('testapp', File::Spec->catfile($self->{t}, '01app.t'));
    $self->create_template('testpod', File::Spec->catfile($self->{t}, '98pod.t'));
    $self->create_template('testpodcoverage', File::Spec->catfile($self->{t}, '99podcoverage.t'));

    $self->create_template('httpdconf', File::Spec->catfile($self->{script_template}, 'httpd.conf'));
}

sub _create_scripts {
    my $self = shift;

    my $path;
    $path = File::Spec->catfile($self->{script}, $self->{prefix} . '_create.pl');
    $self->create_template('appcreate', $path);
    chmod 0700, $path;

    $path = File::Spec->catfile($self->{script}, $self->{prefix} . '_httpd.pl');
    $self->create_template('apphttpdcreate', $path);
    chmod 0700, $path;

    $path = File::Spec->catfile($self->{script}, $self->{prefix} . '_server.pl');
    $self->create_template('appservercreate', $path);
    chmod 0700, $path;

}



sub create_dir {
    my($self, $dir) = @_;

    if (-d $dir) {
        print qq/ exists "$dir"\n/;
        return 0;
    }
    if (mkpath [$dir]) {
        print qq/created "$dir"\n/;
        return 1;
    }
    die qq/Couldn\'t create "$dir", "$!"/;                                                                          
}                                                                                                                                                       

sub create_template {
    my ($self, $file, $path, $opts) = @_;
    $opts ||= {};

    my $t = Template->new;
    my $template = $self->get_file((caller(0))[0], $file);
    return 0 unless $template;

    my $output;
    $t->process(\$template, {%{ $self }, %{ $opts }}, \$output)
        or die qq/Couldn\'t process "$file", / . $t->error();

    $self->create_file($path, $output);
}

sub create_file {
    my($self, $file, $body) = @_;                                                                                                                 

    if (-e $file) {                                                                                                                                   
        print qq/ exists "$file"\n/;
        return 0 unless $self->{force};
    }
    if (my($fh) = IO::File->new("> $file")) {
        binmode $fh;
        print $fh $body;
        print qq/created "$file"\n/;
        return 1;
    }

    die qq/Couldn\'t create "$file", "$!"/;
}

my %cache;
sub get_file {
    my ($self, $class, $file) = @_;

    local $/;
    unless ($cache{$class}) {
        $cache{$class} = eval "package $class; <DATA>";
    }
    my $data = $cache{$class};

    my @files = split /^__(.+)__\r?\n/m, $data;
    shift @files;
    while (@files) {
        my($name, $content) = splice @files, 0, 2;
        return $content if $name eq $file;
    }
    return;
}

1;

__DATA__

__packageclass__
package [% package %];

use strict;
use warnings;

use Soozy qw(-Engine=1 -Debug=1 DebugScreen ConfigLoader);

our $VERSION = '0.01';

__PACKAGE__->setup;

1;

=head1 NAME

[% package %] - Soozy Based Application

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__config__
default:
  name: [% package %]

  V:
    DEFAULT: TT
---
__makefile__
use inc::Module::Install;

name '[% package_suffix %]';
all_from '[% lib_module_pm %]';

requires Soozy => '0.03';

install_script glob('script/*.pl');
auto_install;
WriteAll;
__changes__
This file documents the revision history for Perl extension [% package%].

0.01  [% time %]
        - initial revision, generated by soozy.pl
__testapp__
use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok '[% package %]' }
__testpod__
use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.14";
plan skip_all => 'Test::Pod 1.14 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_files_ok();
__testpodcoverage__
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

all_pod_coverage_ok();
__appcreate__
[% shebang %]

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

pod2usage(1) unless $h->install_component('[% package %]', @ARGV);

1;
=head1 NAME

[% prefix %]_create.pl - Create a new Soozy Component

=head1 SYNOPSIS

[% prefix %]_create.pl [options] C name

[% prefix %]_create.pl [options] M|V|C name helper [options]

[% prefix %]_create.pl [options] M|V|C name :MyApp::Helper::Foo [options]

[% prefix %]_create.pl [options] :MyApp::Helper::Foo [options]

  Options:
   -force        overwrite files
   -help         display this help and exits

 Examples:
   [% prefix %]_create.pl C Search
   [% prefix %]_create.pl V MyTT TT
   [% prefix %]_create.pl M MyDB DBIC::Schema Schema::MyDB dbi:SQLite:/tmp/my.db

=head1 INSPIRE BY

L<Catalyst>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
__apphttpdcreate__
[% shebang %]

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
    system("[% httpd %] -f $config");
} elsif ($ARGV[0] eq 'restart') {
    system(sprintf "kill -HUP `cat %s/httpd.pid`", $h->{logs});
} elsif ($ARGV[0] eq 'stop') {
    system(sprintf "kill `cat %s/httpd.pid`", $h->{logs});
}

1;
=head1 NAME

[% prefix %]_create.pl - Soozy httpd handler

=head1 SYNOPSIS

[% prefix %]_httpd.pl [options] (start|restart|stop)

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
__appservercreate__
[% shebang %]

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
$ENV{[% env %]_ROOT} ||= $root;
$ENV{[% env %]_MODE} ||= $mode;

# This is require instead of use so that the above environment
# variables can be set at runtime.
require [% package %];

[% package %]->run( $port, $host, {
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

[% prefix %]_server.pl - Soozy Testserver

=head1 SYNOPSIS

[% prefix %]_server.pl [options]

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
__httpdconf__
[% TAGS [- -] %]

ServerType           standalone
ServerRoot           [- httpd_root -]
PidFile              [% logs %]/httpd.pid
ScoreBoardFile       [% logs %]/httpd.scoreboard

Timeout              10
KeepAlive            On
MaxKeepAliveRequests 32
KeepAliveTimeout     5

MinSpareServers      2
MaxSpareServers      4
StartServers         2
MaxClients           10
MaxRequestsPerChild  0

LoadModule           perl_module        libexec/libperl.so

ServerName           [% servername %]
Port                 [% port %]

User                 [% user %]
Group                [% group %]

DocumentRoot         [% root %]/html

DefaultType          text/plain

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
ErrorLog             [% logs %]/httpd.error.log
CustomLog            [% logs %]/httpd.access.log combined

SetENV               [- env -]_ROOT  [% root %]
SetENV               [- env -]_DEBUG 1
SetENV               [- env -]_MODE  [% mode %]
PerlSetEnv           PERL5LIB [% PERL5LIB %]

<Location />
    SetHandler       perl-script
    PerlSendHeader   On
    PerlInitHandler  Apache::StatINC
    PerlHandler      [- package -]
</Location>
