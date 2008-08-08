package Soozy::Log::Files;

use strict;
use warnings;
use base qw( Soozy::Log );

use Class::C3;
use File::Spec;
use IO::File;

sub new {
    my($class, $config, @args) = @_;
    my $self = $class->next::method(@args);

    my $files = {};
    for my $file (keys %{ $config->{files} }) {
        for my $level (@{ $config->{files}->{$file} }) {
            push @{ $files->{$level} }, $file;
        }
    }

    $self->{files}  = $files;
    $self->{fh}     = {};
    $self->{config} = $config;

    $self;
}

sub _log {
    my $self    = shift;
    my $level   = shift;
    my $time    = localtime(time);
    my $message = join("\n", @_);
    my @caller  = caller(1);

    my $line = sprintf("[%s] [Soozy] [%s] [%s] [%s/%s] %s\n", $time, $$, $level, $caller[0], $caller[2], $message);

    if ($self->{files}->{$level}) {
        for my $file (@{ $self->{files}->{$level} }) {
            $self->_log_write($file, $line);
        }
    } elsif ($self->{config}->{default}) {
        $self->_log_write($self->{config}->{default}, $line);
    } else {
        print STDERR $line;
    }
}

sub _log_write {
    my($self, $file, $line) = @_;

    my $fh = $self->{fh}->{$file};
    unless ($fh) {
        my $path = File::Spec->catfile($self->{config}->{root}, $file);
        $fh = IO::File->new(">> $path");
        unless ($fh) {
            warn "file: $path: $!";
            return;
        }
        $self->{fh}->{$file} = $fh;
    }

    $fh->print($line);
    $fh->flush;
}

1;

__END__

# example
use Soozy::Log::Files qw( admin login );
__PACKAGE__->log( Soozy::Log::Files->new({
    root  => '/foo/bar/logs',
    default => 'error.log',
    files => {
        'warn.log' => [qw/warn/],
        'app.log' => [qw/admin login/],
    },
}));
