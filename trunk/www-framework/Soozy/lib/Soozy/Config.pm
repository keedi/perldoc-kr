package Soozy::Config;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
			  'S',
			  'ROOT_DIR',
			  'TT_DIR',
			  'TTCACHE_DIR',
			  'DATA_DIR',
			  'BIN_DIR',
			  'SITE',
			  );
sub new () {
    my($class, $S) = @_;

    my $self = bless {}, $class;

    $self->S($S);

    my $root_dir = $S->r->document_root;
    $root_dir =~ s/\/[^\/]+$//;
    $self->ROOT_DIR($root_dir . "/");
    foreach (qw(TT TTCACHE data bin)) {
	my $method = uc($_) . '_DIR';
	$self->$method($self->ROOT_DIR . $_);
    }
    $self->SITE(undef);
    return $self;
}
1;
