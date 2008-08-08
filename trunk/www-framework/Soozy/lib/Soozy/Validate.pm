package Soozy::Validate;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;

sub new () {
    my($class) = @_;

    my $self = bless {
	in => undef,
    }, $class;
    return $self;
}

sub check () {
    my($self, $in, $check) = @_;
    my $errors = [];
    $self->{in} = $in;

    foreach my $keyn (keys %$check) {
	if (ref($check->{$keyn}) eq 'HASH') {
	    my $ret;
	    if (ref($in->{$keyn}) eq 'ARRAY') {
		foreach my $cin (@{$in->{$keyn}}) {
		    $ret = $self->_check($cin, $check->{$keyn});
		}
	    } else {
		$ret = $self->_check($in->{$keyn}, $check->{$keyn});
	    }
	    push(@$errors, @$ret);
	}
    }
    return $errors;
}

sub _check () {
    my($self, $in, $check) = @_;
    my $errors = [];
    my $name = $check->{name};
    my $length = length($in);
    my $min = $check->{min};
    my $max = $check->{max};

    $min = 0 unless ($min =~ /^[0-9]+$/);
    $max = 0 unless ($max =~ /^[0-9]+$/);

    if ($length eq 0) {
	push(@$errors, $name . 'を入力して下さい') if ($min > 0);
    } else {
	if ($length < $min && $min > 0) {
	    push(@$errors, $name . 'は' . sprintf($check->{size_error}, $min) . '以上で入力して下さい');
	} elsif ($length > $max && $max > 0) {
	    push(@$errors, $name . 'は' . sprintf($check->{size_error}, $max) . '以下で入力して下さい');
	} elsif (ref($check->{regex}) eq 'ARRAY') {
	    foreach my $regex (@{$check->{regex}}) {
		unless ($in =~ /$regex/) {
		    push(@$errors, $name . 'は、' . $check->{regex_error});
		    last;
		}
	    }
	}
    }
    return $errors;
}
1;
