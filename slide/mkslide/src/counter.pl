#!/usr/bin/perl 

use strict;
use warnings;

use Counter;

my $count1 = Counter->new;
my $count2 = Counter->new;

print "The counters are the same!\n"
    if $count1 eq $count2;

print "Count is now ", $count1->increment, "\n";
print "Count is now ", $count2->increment, "\n";
print "Count is now ", $count1->increment, "\n";

print "The counters are the same!\n"
    if $count1->value eq $count2->value;
