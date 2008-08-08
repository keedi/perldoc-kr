package Soozy::Engine::HTTP::Restarter;

use strict;
use warnings;
use base qw( Soozy::Engine::HTTP );

use Soozy::Engine::HTTP::Restarter::Watcher;

sub run {
    my($self, $port, $host, $options) = @_;

    $options ||= {};

    # Setup restarter
    unless (my $restarter = fork) {

        # Prepare
        close STDIN;
        close STDOUT;

        my $watcher = Soozy::Engine::HTTP::Restarter::Watcher->new(
            directory => ( 
                $options->{restart_directory} || 
                File::Spec->catdir($FindBin::Bin, '..')
            ),
            regex     => $options->{restart_regex},
            delay     => $options->{restart_delay},
        );

        $host ||= '127.0.0.1';
        while (1) {

            # poll for changed files
            my @changed_files = $watcher->watch;

            # check if our parent process has died
            exit if $^O ne 'MSWin32' and getppid == 1;

            # Restart if any files have changed
            if (@changed_files) {
                my $files = join ', ', @changed_files;
                print STDERR qq/File(s) "$files" modified, restarting\n\n/;

                require IO::Socket::INET;
                require HTTP::Headers;
                require HTTP::Request;

                my $client = IO::Socket::INET->new(
                    PeerAddr => $host,
                    PeerPort => $port
                ) or die "Can't create client socket (is server running?): $!";

                # build the Kill request
                my $req = HTTP::Request->new(
                    'RESTART',
                    '/',
                    HTTP::Headers->new('Connection' => 'close')
                );
                $req->protocol('HTTP/1.0');

                $client->send($req->as_string) or die "Can't send restart instruction: $!";
                $client->close();
                exit;
            }
        }
    }

    $self->next::method($port, $host, $options);
}

1;

__END__

=head1 NAME

Soozy::Engine::HTTP::Restarter - Web Framework

=head1 COPY FROM

L<Catalyst::Engine::HTTP::Restarter>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut

