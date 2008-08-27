#!/usr/bin/perl
use strict;
use warnings;

use GD;

die "Usage: $0 <dir> <prefix> <file1> [ <file2> ... ]\n"
    unless @ARGV >= 3;
my ( $dir, $prefix, @files ) = @ARGV;
mkdir $dir if !-d $dir;

my $loop = $#files / 3 + 1;
for my $cnt ( 1 .. $loop ) {
    my $merge = new GD::Image( 283, 600 );

    my $white = $merge->colorAllocate( 255, 255, 255 );
    my $black = $merge->colorAllocate( 0,   0,   0 );
    my $red   = $merge->colorAllocate( 255, 0,   0 );
    my $blue  = $merge->colorAllocate( 0,   0,   255 );

    $merge->transparent($white);
    $merge->interlaced('true');
    $merge->setAntiAliased($black);

    my $y = 0;
    my $idx = ($cnt - 1) * 3;
    for my $file ( @files[ $idx, $idx + 1, $idx + 2 ] ) {
        if ( $file && -f $file ) {
            my $bg = newFromPng GD::Image($file);
            $merge->copyResampled($bg, 0, $y, 0, 0, 283, 198, 283, 198);
        }
        $y += 200;
    }

    my $path = sprintf("$dir/$prefix%03d.png", $cnt);
    print "$path\n";
    open my $fh, '>', $path
        or do {
            warn "cannot open $path : $!\n";
            next;
        };
    print $fh $merge->png;
    close $fh;
}


