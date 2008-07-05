#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  mkslide.pl
#
#        USAGE:  ./mkslide.pl index.txt > index.html
#
#  DESCRIPTION:  텍스트 문서를 이용해서 html 슬라이드를 만들어 줍니다.
#
#      OPTIONS:  ---
# REQUIREMENTS:
#               YAML
#               Readonly
#               Switch::Perlish
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  김도형 (Keedi Kim), <keedi@naver.com>
#      COMPANY:  Emstone; Perlmania
#      VERSION:  0.01
#      CREATED:  2008년 06월 21일 09시 48분 33초 KST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use YAML;
use Readonly;
use Switch::Perlish;

Readonly my $CONF_FILE => 'slide.conf';
Readonly my %TAG       => (
	code => qr{ ^ \.code    }x,
	text => qr{ ^ \.text    }x,
	img  => qr{ ^ \.img     }x,
	ul   => qr{ ^ \s* [*+-] }x,
	ol   => qr{ ^ \d+ \.    }x,
);
Readonly my $DEFAULT_CONF => <<'END_DEFAULT_CONF';
---
macro:
    title:      Inser Title
    link:       http://insert.your.link/index.html
    email:      email@address.com
    name:       Insert Name
    company:    Insert Company
    community:  Insert Community
path:
    css:        slide.css
    javascript: slide.js
    images:     images
END_DEFAULT_CONF

my $slide_info = -f $CONF_FILE ? YAML::LoadFile($CONF_FILE)
               : YAML::Load($DEFAULT_CONF);

print apply_slide_info( start_slide() );

LOOP_LINES:
while ( my $line = <> ) {
    chomp $line;
    next unless $line;

    # 회피문자 처리
    $line = convert_escaped_char( $line );

    switch $line, sub {
        case qr/$TAG{code}/, sub {
            # 코드 태그 처리
            my @sub_lines;

            LOOP_CODE_LINES:
            while ( my $sub_line = <> ) {
                chomp $sub_line;
                last LOOP_CODE_LINES if $sub_line =~ m/$TAG{code}/;
                push @sub_lines, convert_escaped_char( $sub_line );
            }
            print "\n", code_markup(@sub_lines);
        };
        case qr/$TAG{text}/, sub {
            # 텍스트 태그 처리
            my @sub_lines;

            LOOP_TEXT_LINES:
            while ( my $sub_line = <> ) {
                chomp $sub_line;
                last LOOP_TEXT_LINES if $sub_line =~ m/$TAG{text}/;
                push @sub_lines, convert_escaped_char( $sub_line );
            }
            print "\n", text_markup(@sub_lines);
        };
        case qr/$TAG{ul}/, sub {
            # 순서 없는 리스트 태그 처리
            my @sub_lines;
            push @sub_lines, convert_escaped_char( $line );

            LOOP_UL_LINES:
            while ( my $sub_line = <> ) {
                chomp $sub_line;
                if ( $sub_line !~ m/$TAG{ul}/ ) {
                    $line = $sub_line;
                    last LOOP_UL_LINES;
                }
                push @sub_lines, convert_escaped_char( $sub_line );
            }
            print "\n", ul_markup(@sub_lines);
        };
        case qr/$TAG{img}/, sub {
            # 이미지 태그 처리
            print "\n", img_markup($line);
        };
        default sub {
            # 일반 적인 경우
            print "\n", normal_markup($line);
        };
    };
}

print "\n", end_slide();

sub convert_escaped_char {
    my $line = shift;

    return unless $line;

    $line =~ s/</&lt;/g;
    $line =~ s/>/&gt;/g;

    return $line;
}

sub img_markup {
    my ( $line ) = @_;
    my ( $tag, $file, $name ) = split q{ }, $line, 3;

    return unless $file;

    my $img_str;
    if ( $name ) {
        $img_str = qq{$name<br>\n<img src="$slide_info->{path}{images}/$file" alt="$name">};
    }
    else {
        $img_str = qq{<img src="$slide_info->{path}{images}/$file">};
    }

    my $str = <<"END_SECTION";
<div>
<p>
$img_str
</p>
</div>
END_SECTION

    return $str;
}

sub ul_markup {
    my ( @lines ) = @_;

    my $concat_line = join "\n", map { s/$TAG{ul}//; "<li>$_</li>"; } @lines;

    my $str = <<"END_SECTION";
<div>
<ul>
$concat_line
</ul>
</div>
END_SECTION

    return $str;
}

sub normal_markup {
    my ( $line ) = @_;

    my $str = <<"END_SECTION";
<div>
<h1>$line</h1>
</div>
END_SECTION

    return $str;
}

sub code_markup {
    my ( @lines ) = @_;

    my $concat_line = join "\n", @lines;

    my $str = <<"END_SECTION";
<div>
<pre>
$concat_line
</pre>
</div>
END_SECTION

    return $str;
}

sub text_markup {
    my ( @lines ) = @_;

    my $concat_line = join "<br>\n", @lines;

    my $str = <<"END_SECTION";
<div>
<p>
$concat_line
</p>
</div>
END_SECTION

    return $str;
}

sub apply_slide_info {
    my $str = shift;

    return unless $str;

    for my $tag ( keys %{$slide_info->{macro}} ) {
        $str =~ s/###$tag###/$slide_info->{macro}{$tag}/gi;
    }

    return $str;
}

sub start_slide {
    my $str = <<"END_START_SLIDE";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/x html1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ko" lang="ko">

<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"></meta>
<link rel="stylesheet" href="$slide_info->{path}{css}" type="text/css" />
<title>###TITLE###</title>
<script language="javascript" src="$slide_info->{path}{javascript}"></script>
</head>

<body>
<table id="frame" class="frame">
<tr>
<td colspan="3" id="screen" height="90%"
class="screen" align="center" valign="center">
</td>
</tr>
<tr>
<td nowrap align="left"><a href="javascript:slide.prev()">prev</a>
<input id="translate" type="checkbox" onclick="slide.go()">Translate</td>
<td width="100%"></td>
<td nowrap align="right">Page
<input id="pagenum" type="text" size="2" value="0"
onkeyup="slide.go(\$('pagenum').value)" onclick="\$('pagenum').select()">
<a href="javascript:slide.next()">next</a></td>
</tr>
</table>

<div id="slides">

<div>
<h1>###TITLE###</h1>
</div>

<div>
<p>
by <a href="mailto:###EMAIL###">###NAME###</a>
</p>
<p>
###COMPANY###<br>
###COMMUNITY###
</p>
</div>

<div>
<p>문서는 이곳에서도<br>볼 수 있습니다:</p>
<p><a target="_blank" href="###LINK###">###LINK###</a></p>
</div>
END_START_SLIDE

    return $str;
}

sub end_slide {
    my $str = <<'END_END_SLIDE';
<div>
<h1>Any Question?</h1>
</div>

<div>
<h1>Thank you!</h1>
</div>

</div><!--contents-->
</body>
</html>
END_END_SLIDE

    return $str;
}
