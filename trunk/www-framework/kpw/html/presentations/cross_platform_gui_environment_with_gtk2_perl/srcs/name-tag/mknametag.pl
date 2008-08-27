#!/usr/bin/perl
use strict;
use warnings;

use GD;

die "Usage: $0 <no> <name> <type> > file.png\n"
    unless @ARGV >= 2;
my ( $no, $name, $type ) = @ARGV;

# create a new image
my $bg = newFromPng GD::Image('name-tag-template.png');
my $gd = new GD::Image( 283, 198 );

my $white = $gd->colorAllocate( 255, 255, 255 );
my $black = $gd->colorAllocate( 0,   0,   0 );
my $red   = $gd->colorAllocate( 255, 0,   0 );
my $blue  = $gd->colorAllocate( 0,   0,   255 );

$gd->transparent($white);
$gd->interlaced('true');
$gd->setAntiAliased($black);

if ( $type ) {
    $gd->stringFT(
        $black,
        './SeoulNamsanEB.ttf',
        25, 0, 20, 50,
        $type,
        {
            linespacing => 1.0,
            charmap     => 'Unicode',
        }
    );

    $gd->stringFT(
        $black,
        './SeoulNamsanEB.ttf',
        35, 0, 70, 105,
        $name,
        {
            linespacing => 1.0,
            charmap     => 'Unicode',
        }
    );
}
else {
    $gd->stringFT(
        $black,
        './SeoulNamsanEB.ttf',
        35, 0, 30, 80,
        $name,
        {
            linespacing => 1.0,
            charmap     => 'Unicode',
        }
    );
}

$gd->stringFT(
    $black,
    './SeoulNamsanEB.ttf',
    16, 0, 240, 30,
    $no,
    {
        linespacing => 1.0,
        charmap     => 'Unicode',
    }
);

binmode STDOUT;

$bg->copyResampled($gd, 0, 0, 0, 0, 283, 198, 283, 198);
print $bg->png;

