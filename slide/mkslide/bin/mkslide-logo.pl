#!/usr/bin/perl 

use 5.010;
use common::sense;
use YAML;
use Readonly;
use GD;

Readonly my $CONF_FILE => 'slide.conf';

my $slide_info = YAML::LoadFile($CONF_FILE);

my $subject = $slide_info->{macro}{title};
my $bg_image = $slide_info->{logo}{template};

# create a new image
my $gd = GD::Image->new( 800, 165 );
my $bg = GD::Image->new( 1000, 165 );
if ( $bg_image ) {
    $bg = GD::Image->newFromPng( $bg_image );
}

my $bg_color = $gd->colorAllocate( 3,   29,  64 );
my $white    = $gd->colorAllocate( 255, 255, 255 );
my $black    = $gd->colorAllocate( 0,   0,   0 );
my $red      = $gd->colorAllocate( 255, 0,   0 );
my $blue     = $gd->colorAllocate( 0,   0,   255 );

$gd->transparent($bg_color);
$gd->interlaced('true');
$gd->setAntiAliased($black);

$bg->transparent($bg_color);
$bg->interlaced('true');
$bg->setAntiAliased($black);

$gd->useFontConfig(1);
bordered_text($gd, 1, $black, $white, './SeoulNamsanEB.ttf', 30, 0, 20, 50, $subject);
#bordered_text($gd, 1, $black, $white, 'NanumMyeongjo:italic', 25, 0, 20, 50, $subject);
#bordered_text($gd, 2, $black, $white, 'Arial:italic', 25, 0, 20, 50, $subject);

binmode STDOUT;

$bg->copyResampled($gd, 250, 0, 0, 0, 800, 165, 800, 165);
print $bg->png;

sub bordered_text {
    my ( $image, $width, $bordercolor, $fgcolor, $fontname, $ptsize, $angle, $x, $y, $string ) = @_;

    my $sx = $x - $width;
    my $sy = $y - $width;
    my $n  = $width * 2;
    for my $dx ( 0 .. $n ) {
        for my $dy ( 0 .. $n ) {
            $image->stringFT(
                $bordercolor,
                $fontname,
                $ptsize, $angle, ($sx + $dx), ($sy + $dy),
                $string,
                {
                    linespacing => 1.0,
                    charmap     => 'Unicode',
                }
            );
        }
    }

    $image->stringFT(
        $fgcolor,
        $fontname,
        $ptsize, $angle, $x, $y,
        $string,
        {
            linespacing => 1.0,
            charmap     => 'Unicode',
        }
    );
}
