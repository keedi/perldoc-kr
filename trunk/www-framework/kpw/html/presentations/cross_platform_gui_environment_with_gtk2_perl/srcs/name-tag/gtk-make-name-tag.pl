#!/usr/bin/perl 

use strict;
use warnings;

use Encode qw(decode);
use Gtk2 -init;

my $DECODING = 'utf-8';
sub _d { decode($DECODING, shift) }

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

    $hbox = Gtk2::HBox->new(0, 5);
    $label = Gtk2::Label->new(_d('상태:'));
    $entry = Gtk2::Entry->new();
    $hbox->pack_start_defaults($label);
    $hbox->pack_start_defaults($entry);
    $vbox->pack_start_defaults($hbox);
    $widget_of{type} = $entry;

my $button;
    $hbox = Gtk2::HBox->new(0, 5);

    $button = Gtk2::Button->new(_d('초기화'));
    $button->signal_connect(clicked => \&reset_text_entry);
    $hbox->pack_start_defaults($button);

    $button = Gtk2::Button->new(_d('생성'));
    $button->signal_connect(clicked => \&generate_name_tag);
    $hbox->pack_start_defaults($button);

    $vbox->pack_start_defaults($hbox);

$window->add($vbox);
$window->show_all;

Gtk2->main;

sub reset_text_entry {
    my $self = shift;

    $widget_of{no}->set_text(q{});
    $widget_of{name}->set_text(q{});
    $widget_of{type}->set_text(q{});

    $widget_of{window}->set_focus($widget_of{name});
}

sub generate_name_tag {
    my $self = shift;

    my $no   = $widget_of{no}->get_text;
    my $name = $widget_of{name}->get_text;
    my $type = $widget_of{type}->get_text;

    print STDERR "$no - $name - $type\n";

    my $cmd = "./mknametag.pl '$no' '$name' '$type' > tmp.png\n";
    print STDERR $cmd;
    system $cmd;
    system 'eog tmp.png';
}
