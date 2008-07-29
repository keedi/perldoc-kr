#!/usr/bin/perl 

use strict;
use warnings;

use DBI::NeoSingleton;

# config variables
my $platform  = "mysql";
my $database  = "store";
my $host      = "localhost";
my $port      = "3306";
my $user      = "username";
my $pw        = "password";
my $tablename = "inventory";

# data source name
my $dsn = "dbi:$platform:$database:$host:$port";

my $dbh = DBI::NeoSingleton->connect( $dsn, $user, $pw,)
    or die "Database connection not made: $DBI::NeoSingleton::errstr";

#
# do something useful
#

$dbh->disconnect();


