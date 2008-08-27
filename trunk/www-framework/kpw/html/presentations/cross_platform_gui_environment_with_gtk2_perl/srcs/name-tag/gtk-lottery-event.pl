#!/usr/bin/perl 

use strict;
use warnings;

use Encode qw(decode);
use Gtk2 -init;
use List::Util qw(shuffle);

my $DECODING = 'utf-8';
sub _d { decode($DECODING, shift) }

my $file = shift;
open my $fh, $file
    or die "cannot open file: $file $!\n";
binmode $fh, ":utf8";
my @people = <$fh>;
chomp @people;
my @random_people = shuffle @people;
my $idx = 0;
close $fh;

my %widget_of;

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect(destroy => sub { Gtk2->main_quit });
$widget_of{window} = $window;

my $vbox = Gtk2::VBox->new(0, 5);

my ( $hbox, $label, $entry );

    $hbox = Gtk2::HBox->new(0, 5);
    $label = Gtk2::Label->new(_d('이름:'));
    $entry = Gtk2::Entry->new();
    $hbox->pack_start_defaults($label);
    $hbox->pack_start_defaults($entry);
    $vbox->pack_start_defaults($hbox);
    $widget_of{name} = $entry;

    $hbox = Gtk2::HBox->new(0, 5);
    $label = Gtk2::Label->new(_d('번호:'));
    $entry = Gtk2::Entry->new();
    $hbox->pack_start_defaults($label);
    $hbox->pack_start_defaults($entry);
    $vbox->pack_start_defaults($hbox);
    $widget_of{no} = $entry;

my $button;
    $hbox = Gtk2::HBox->new(0, 5);

    $button = Gtk2::Button->new(_d('경품 추첨'));
    $button->signal_connect(clicked => \&generate_name_tag);
    $hbox->pack_start_defaults($button);

    $vbox->pack_start_defaults($hbox);

$window->add($vbox);
$window->show_all;

Gtk2->main;

sub generate_name_tag {
    my $self = shift;

    my ( $confirm, $no, $name )
        = split /\|/, $random_people[$idx++];
    $name = join ' ', split //, $name if $name !~ /[a-zA-Z]/;

    $widget_of{no}->set_text( _d( $no ) );
    $widget_of{name}->set_text( ( $name ) );
    my $type = _d('축 당첨!! :-)');

    print STDERR "$no - $name - $type\n";

    my $cmd = "./mknametag.pl '$no' '$name' '$type' > tmp.png\n";
    print STDERR $cmd;
    system $cmd;
    system 'eog tmp.png';
}
