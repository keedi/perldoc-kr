package DBI::Singleton;

use strict;
use warnings;

use base qw(DBI);
use DBI;

my $dbh = undef;

sub connect {
    my $class = shift;

    return $dbh if defined $dbh;

    $dbh = DBI->connect( @_ );

    return $dbh;
}

1;
