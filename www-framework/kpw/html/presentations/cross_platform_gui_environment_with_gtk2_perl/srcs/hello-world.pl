#!/usr/bin/perl
use strict;
use warnings;

use Encode qw(decode);
use Gtk2 -init;

# 한글 깨짐 문제를 해결하기 위한 래퍼함수
my $DECODING = 'utf-8';
sub _d { decode( $DECODING, shift ) }

# 윈도우 개체 생성
# 윈도우 종료 표시(x)를 눌렀을 때 동작 정의
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect(destroy => sub { Gtk2->main_quit });

# 수직 박스 개체 생성
my $vbox = Gtk2::VBox->new(0, 5);

# 수직 박스에 들어갈 레이블 개체 생성
# 수직 박스에 레이블 끼워 넣기
my $label = Gtk2::Label->new(_d('버튼을 누르면 프로그램을 종료합니다!'));
$vbox->pack_start_defaults($label);

# 수직 박스에 들어갈 버튼 개체 생성
# 버튼 클릭시 동작 정의
# 수직 박스에 버튼 끼워 넣기
my $button = Gtk2::Button->new('Hello World! And Goodbye! :-)');
$button->signal_connect(clicked => sub { Gtk2->main_quit });
$vbox->pack_start_defaults($button);

# 윈도우에 수직 박스 끼워 넣기
# 윈도우 및 하부의 모든 개체를 화면에 보이기
$window->add($vbox);
$window->show_all;

# Gtk2의 GUI 메인 루프
Gtk2->main;
