package Soozy::Charset;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use base qw(Class::Accessor);

use Jcode;

sub new {
    my($class, $S) = @_;
    bless {S => $S}, $class;
}

sub convert_input_param {
    my($self, $S) = @_;
    my $in = {};
    for my $p ($S->cgi->param) {
	my $key = $self->decode($p);
	my $value = $self->decode($S->cgi->param($p));
	my @cb = $S->cgi->param($p);
	if (scalar(@cb) > 1) {
	    #checkbox ref is ARRAY
	    $in->{$key} = [];
	    for my $cvalue (@cb) {
		$cvalue = $self->decode($cvalue);
		push(@{$in->{$key}}, $cvalue);
	    }
	} else {
	    $in->{$key} = $value;
	}
    }
    return $in;
}

sub decode {
    my($self, $str) = @_;
    return $str;
}
sub get_charset {}
sub output_filter {
    my($self, $contents) = @_;
    return $contents;
}
1;
