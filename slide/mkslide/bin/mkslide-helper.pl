#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;

die usage() unless @ARGV == 2;

my $src_dir  = shift || '../mkslide';
my $dest_dir = shift || '.';

my @src_files = qw(
    Makefile
    bin
    logo.png
    slide.css
    slide.js
);

my $symlink_exists = eval { symlink("", ""); 1; };

mkdir 'images';
copy("$src_dir/$_", "$dest_dir/$_") for ( qw( index.txt sldie.conf ) );

for my $src_file ( @src_files ) {
	my $src_path  = "$src_dir/$src_file";
	my $dest_path = "$dest_dir/$src_file";

    if ( $symlink_exists ) {
        symlink($src_path, $dest_path);
    }
    else {
        copy($src_path, $dest_path);
    }
}

sub usage {
    return <<"END_USAGE";
Usage: $0 <mkslide_dir> <dest_dir>

Example:
    $0 ../mkslide .
    $0 ~/bin/mkslide ~/presentation/slide/about-perl
END_USAGE
}

