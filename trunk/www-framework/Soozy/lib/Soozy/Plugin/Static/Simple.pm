package Soozy::Plugin::Static::Simple;

use strict;
use warnings;
use base qw( Soozy::Plugin );

use Class::C3;
use File::stat;
use File::Spec::Functions ();
use IO::File;
use MIME::Types;
    
__PACKAGE__->mk_classdata(qw/ _static_mime_types /);
__PACKAGE__->mk_accessors(qw/ _static_file _static_debug_message /);

sub initialize {
    my $class = shift;

    $class->next::method(@_);

    $class->config->{static}->{dirs} ||= [];
    $class->config->{static}->{include_path} ||= [ $class->path_to('html') ];
    $class->config->{static}->{mime_types} ||= {};
    $class->config->{static}->{ignore_extensions} ||= [qw/ tmpl tt tt2 html xhtml /];
    $class->config->{static}->{ignore_dirs} ||= [];
    $class->config->{static}->{debug} ||= $class->debug;
    if ( ! defined $class->config->{static}->{no_logs}) {
        $class->config->{static}->{no_logs} = 1;
    }

    # load up a MIME::Types object, only loading types with
    # at least 1 file extension
    $class->_static_mime_types(MIME::Types->new(only_complete => 1));

    # preload the type index hash so it's not built on the first request
    $class->_static_mime_types->create_type_index;
}

sub prepare {
    my $self = shift;
    $self->next::method(@_);

    my $path = $self->req->path;
    $path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

    # is the URI in a static-defined path?
    for my $dir (@{ $self->config->{static}->{dirs} }) {
        my $re = ( $dir =~ /^qr\//xms ) ? eval $dir : qr/^${dir}/;
        $@ and $self->log->error( "Error compiling static dir regex '$dir': $@");
        if ($path =~ $re) {
            unless ($self->_locate_static_file($path)) {
                $self->res->status(404);
            }
        }
    }

    if ($self->_static_file && $self->res->status eq 404) {
        $self->res->status(200);
    } elsif ($self->res->status eq 404) {
        $self->_static_file(sub { "404: file not found: $path" });
    }
    
    # Does the path have an extension?
    # if ($path =~ /.*\.(\S{1,})$/xms) {
    #     # and does it exist?
    #     $self->_locate_static_file($path);
    # }
    
}

sub controller_method {
    my $self = shift;
    $self->next::method(@_) unless $self->_static_file;
}

sub forward {
    my $self = shift;
    return $self->next::method(@_) unless $self->_static_file;
    return $self->_serve_static;
}

sub dispatcher_output {
    my $self = shift;
    $self->next::method(@_);
}

sub _locate_static_file {
    my($self, $path) = @_;

    $path = File::Spec::Functions::catdir( File::Spec::Functions::no_upwards( File::Spec::Functions::splitdir( $path ) ) );

    my @ipaths = @{ $self->config->{static}->{include_path} };
    my $dpaths;
    my $count = 64; # maximum number of directories to search

    DIR_CHECK:
    while (@ipaths && --$count) {
        my $dir = shift @ipaths || next DIR_CHECK;
        if (ref $dir eq 'CODE') {
            eval { $dpaths = &$dir($self) };
            if ($@) {
                $self->log->error('Static::Simple: include_path error: ' . $@);
            } else {
                unshift @ipaths, @{ $dpaths };
                next DIR_CHECK;
            }
        } else {
            $dir =~ s/(\/|\\)$//xms;
            if (-d $dir && -f "$dir/$path") {

                # do we need to ignore the file?
                for my $ignore (@{ $self->config->{static}->{ignore_dirs} }) {
                    $ignore =~ s{(/|\\)$}{};
                    next DIR_CHECK if $path =~ /^$ignore(\/|\\)/;
                }
     
                # do we need to ignore based on extension?
                for my $ignore_ext (@{ $self->config->{static}->{ignore_extensions} }) {
                    next DIR_CHECK if $path =~ /.*\.${ignore_ext}$/ixms;
                }

                return $self->_static_file("$dir/$path");
            }
        }
    }

    return;
}

sub _serve_static {
    my $self = shift;

    if (ref $self->_static_file eq 'CODE') {
        my $code = $self->_static_file;
        $self->res->body(&$code());
        return 1;
    }
           
    my $full_path = $self->_static_file; 
    $self->log->info($full_path);
    my $type      = $self->_ext_to_type($full_path);
    my $stat      = stat $full_path;

    $self->res->headers->content_type($type);
    $self->res->headers->content_length($stat->size);
    $self->res->headers->last_modified($stat->mtime);

    my $fh = IO::File->new($full_path, 'r');
    if (defined $fh) {
        binmode $fh;
        $self->res->body($fh);
    } else {
        die "Unable to open $full_path for reading";
    }

    return 1;
}

sub _ext_to_type {
    my($self, $full_path) = @_;

    if ($full_path =~ /.*\.(\S{1,})$/xms ) {
        my $ext = $1;
        my $user_types = $self->config->{static}->{mime_types};
        my $type = $user_types->{$ext} || $self->_static_mime_types->mimeTypeOf($ext);

        return (ref $type) ? $type->type : $type if $type;
    }
    return 'text/plain';
}

1;

__END__

=head1 NAME

Soozy::Plugin::Static::Simple - Web Framework

=head1 COPY FROM

L<Catalyst::Plugin::Static::Simple>

=head1 AUTHOR

Kazuhiro Osawa

=head1 LICENSE

perl

=cut
