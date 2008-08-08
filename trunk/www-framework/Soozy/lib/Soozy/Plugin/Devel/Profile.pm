package Soozy::Plugin::Devel::Profile;

use strict;
use warnings;

use base qw( Soozy::Plugin );

use Devel::Profile;
use Time::HiRes ();

sub prepare {
    my $self = shift;
    if ($self->debug) {
        DB::reset;
	$self->{__devel_profile_start_time} = Time::HiRes::time;
    }
    $self->next::method(@_);
}

sub dispatcher_output_headers {
    my $self = shift;
    return $self->next::method(@_) unless $self->debug;
    return $self->next::method(@_) if $self->res->content_type && $self->res->content_type !~ /html/;

    my $time = Time::HiRes::time - $self->{__devel_profile_start_time};
    local $ENV{PERL_PROFILE_FILENAME} = ($self->config->{devel_profile_dump_dir} || '/tmp') . '/' . $self->envprefix . "_devel_profile_$$.dump";
    DB::save();

    my $profile = '';
    if (open my $fh, '<', $ENV{PERL_PROFILE_FILENAME}) {
        $profile = do { local $/; <$fh> };
        close $fh;
    }

    my $output = sprintf '<div id="sooz_devel_profile">
    <h2>Devel::Profile Report</h2>
<pre>total time: %s

%s
</pre>
</div>', $time, $profile;
    unlink $ENV{PERL_PROFILE_FILENAME};

    my $body = $self->res->body;
    unless (ref($body)) {
        $body .= $output unless $body =~ s!(</body>.*)$!<pre>$output</pre>$1!im;
        $self->res->body($body);
    }

    $self->next::method(@_);
}

1;
