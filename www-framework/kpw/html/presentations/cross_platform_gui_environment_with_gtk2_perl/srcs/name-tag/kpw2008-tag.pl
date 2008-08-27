#!/usr/bin/perl 

use strict;
use warnings;
use utf8;

my $cmd = './mknametag.pl';
die "Usage: cat list.txt | $0 <dir>\n"
    unless @ARGV == 1;
my $dir = shift;
mkdir $dir if !-d $dir;

binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";

while ( <> ) {
    chomp;
    my ( $confirm, $no, $name ) = split /\|/;
    $name = join ' ', split //, $name if $name !~ /[a-zA-Z]/;
    if ( $confirm =~ /staff/i ) {
        my $path = sprintf("$dir/staff-%03d.png", $no);
        print("$cmd '$no' '$name' 'STAFF'> $path\n");
        system("$cmd '$no' '$name' 'STAFF'> $path");
    }
    elsif ( $confirm =~ /speaker/i ) {
        my $path = sprintf("$dir/speaker-%03d.png", $no);
        print("$cmd '$no' '$name' 'Speaker'> $path\n");
        system("$cmd '$no' '$name' 'Speaker'> $path");
    }
    else {
        my $path = sprintf("$dir/%03d.png", $no);
        print("$cmd '$no' '$name' > $path\n");
        system("$cmd '$no' '$name' > $path");
    }
}
