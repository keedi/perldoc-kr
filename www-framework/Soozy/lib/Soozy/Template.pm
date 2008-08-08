package Soozy::Template;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;

use Template;


sub new () {
    my($class, $path, $c) = @_;
    bless {
	path => $path,
        c => $c,
	S => $c,
        _options => {
            ABSOLUTE => 1,
            RELATIVE => 1,
            INCLUDE_PATH => $path->{_path} . "/include",
	    COMPILE_DIR  => $c->conf->TTCACHE_DIR,
	    COMPILE_EXT  => '.ttc',
        },
        _params  => {
	    c       => $c,
	    S       => $c->tmpl_param,
            config  => $c->conf,
            r       => $c->in,
            stash   => $c->stash,
            session => undef,
        },
    }, $class;
}

sub gen {
    my $self = shift;
    my %config = %{$self->{_options}};
    my $input  = $self->{path}->{_path} . "/" . $self->{path}->{_filename};
    my $template = Template->new(\%config);
    unless (-e $input) {
	die 'Not Found Template HTML File:' . $input;
    }
    $self->{_params}->{S} = $self->{S}->tmpl_param;
    $self->{_params}->{in} = $self->{S}->in;
    $template->process($input, $self->{_params}, \my $output) or die $template->error;
    return $output;
}


sub set_option {
    my $self = shift;
    while (my($key, $val) = splice @_, 0, 2) {
        $self->{_options}->{$key} = $val;
    }
}

sub add_option {
    my $self = shift;
    while (my($key, $val) = splice @_, 0, 2) {
        if (! exists $self->{_options}->{$key}) {
            $self->{_options}->{$key} = $val;
        }
        elsif (ref $self->{_options}->{$key} eq 'ARRAY') {
            push @{$self->{_options}->{$key}}, $val;
        }
        else {
            $self->{_options}->{$key} = [ $self->{_options}->{$key}, $val ];
        }
    }
}

sub param {
    my $self = shift;
    if (@_ == 0) {
        return keys %{$self->{_params}};
    }
    elsif (@_ == 1) {
        return $self->{_params}->{$_[0]};
    }
    else {
        while (my($key, $val) = splice @_, 0, 2) {
            $self->{_params}->{$key} = $val;
        }
    }
}
1;
