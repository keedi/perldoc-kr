package Soozy::Engine::HTTP::Restarter::Watcher;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );

use File::Find;
use File::Modified;
use File::Spec;
use Time::HiRes qw/sleep/;

__PACKAGE__->mk_accessors(qw/ delay directory modified regex watch_list /);

sub new {
    my($class, %args) = @_;

    my $self = bless { %args }, $class;
    $self->_init;

    $self;
}

sub _init {
    my $self = shift;

    my $watch_list = $self->_index_directory;
    $self->watch_list($watch_list);

    $self->modified(
        File::Modified->new(
            method => 'mtime',
            files  => [ keys %{$watch_list} ],
        )
    );
}

sub watch {
    my $self = shift;

    my @changes;
    my @changed_files;

    sleep $self->delay || 1;

    eval { @changes = $self->modified->changed };
    if ($@) {
        # File::Modified will die if a file is deleted.
        my ($deleted_file) = $@ =~ /stat '(.+)'/;
        push @changed_files, $deleted_file || 'unknown file';
    }

    if (@changes) {

        # update all mtime information
        $self->modified->update;

        # check if any files were changed
        @changed_files = grep { -f $_ } @changes;

        # Check if only directories were changed.  This means
        # a new file was created.
        unless (@changed_files) {

            # re-index to find new files
            my $new_watch = $self->_index_directory;

            # look through the new list for new files
            my $old_watch = $self->watch_list;
            @changed_files = grep { !defined $old_watch->{$_} } keys %{$new_watch};

            return unless @changed_files;
        }

        # Test modified pm's
        for my $file (@changed_files) {
            next unless $file =~ /\.pm$/;
            if ( my $error = $self->_test($file) ) {
                print STDERR qq/File "$file" modified, not restarting\n\n/;
                print STDERR '*' x 80, "\n";
                print STDERR $error;
                print STDERR '*' x 80, "\n";
                return;
            }
        }
    }

    return @changed_files;
}

sub _index_directory {
    my $self = shift;

    my $dir   = $self->directory || die "No directory specified";
    my $regex = $self->regex     || '\.pm$';
    my %list;

    finddepth({
        wanted => sub {
            my $file = File::Spec->rel2abs($File::Find::name);
            return unless $file =~ /$regex/;
            return unless -f $file;
            $file =~ s{/script/..}{};
            $list{$file} = 1;

            # also watch the directory for changes
            my $cur_dir = File::Spec->rel2abs($File::Find::dir);
            $cur_dir =~ s{/script/..}{};
            $list{$cur_dir} = 1;
        },
        no_chdir => 1
    }, $dir);
    return \%list;
}

sub _test {
    my ( $self, $file ) = @_;

    delete $INC{$file};
    local $SIG{__WARN__} = sub { };

    print STDERR "require '$file'\n";
    open my $olderr, '>&STDERR';
    open STDERR, '>', File::Spec->devnull;
    eval "require '$file'";
    open STDERR, '>&', $olderr;

    return ($@) ? $@ : 0;
}

1;

__END__

=head1 NAME

Soozy::Engine::HTTP::Restarter::Watcher - Web Framework

=head1 COPY FROM

L<Catalyst::Engine::HTTP::Restarter::Watcher>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut
