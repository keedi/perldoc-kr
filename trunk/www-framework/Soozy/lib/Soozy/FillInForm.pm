package Soozy::FillInForm;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use HTML::FillInForm;
use base qw(Class::Accessor Class::Data::Inheritable);
__PACKAGE__->mk_accessors(
			  'fill',
			  'fobject',
			  'fdat',
			  'target',
			  'ignore_fields',
			  'fill_password',
			  );

sub new {
    my($class, $S) = @_;
    bless {
        fill    => HTML::FillInForm->new,
        fobject => undef,
        fdat    => undef,
        target  => undef,
        ignore_fields => [],
	fill_password => undef,
    };
}


sub gen {
    my($self, $html) = @_;
    my %options = (
		   scalarref => \$html,
		   target    => $self->target,
		   fill_password => $self->fill_password,
		   ignore_fields => $self->ignore_fields,
		   );
    if ($self->fdat) {
        $options{fdat} = $self->fdat;
    } elsif ($self->fobject) {
        $options{fobject} = $self->fobject;
    }
    return $self->fill->fill(%options);
}
1;
