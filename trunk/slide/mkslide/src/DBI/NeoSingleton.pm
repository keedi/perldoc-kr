package DBI::NeoSingleton;

use strict;
use warnings;

use base qw(Class::Singleton);
use vars qw($errstr);

use DBI;

*errstr = *DBI::errstr;

sub _new_instance {
    my $class = shift;

    return DBI->connect( @_ );
}

1;
