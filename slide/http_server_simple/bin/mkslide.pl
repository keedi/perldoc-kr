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
	code    => qr{ ^ \.code    }x,
	text    => qr{ ^ \.text    }x,
	img     => qr{ ^ \.img     }x,
	ul      => qr{ ^ \.ul      }x,
	ol      => qr{ ^ \.ol      }x,
	ul_item => qr{ ^ \s* [*+-] }x,
	ol_item => qr{ ^ \d+ \.    }x,
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

    switch $line, sub {
        case qr/$TAG{code}/, sub {
            # 코드 태그 처리
            my @sub_lines;
            my %opt;
            my $opt_str = (split / /, $line, 2)[1];
            if ( $opt_str ) {
                map {
                    my ( $name, $val ) = split /=/, $_, 2;
                    $val =~ s/^" //x;
                    $val =~ s/ "$//x;
                    $opt{$name} = $val;
                } $opt_str =~ m/ ( \w+ = (?: "[^"]*" | \w* ) ) /gx;
            }

            if ( $opt{src} ) {
                open my $fh, $opt{src}
                    or do {
                        push @sub_lines, "Cannot open file [$opt{src}]: $!";
                        print "\n", code_markup(@sub_lines);
                        stop;
                    };
                @sub_lines = <$fh>;
                close $fh;
                print "\n", code_markup(@sub_lines);
                stop;
            }

            LOOP_CODE_LINES:
            while ( my $sub_line = <> ) {
                last LOOP_CODE_LINES if $sub_line =~ m/$TAG{code}/;
                push @sub_lines, $sub_line;
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
                push @sub_lines, $sub_line;
            }
            print "\n", text_markup(@sub_lines);
        };
        case qr/($TAG{ul})|($TAG{ul_item})/, sub {
            # 순서 없는 리스트 태그 처리
            my @sub_lines;
            my %opt;
            if ( $line =~ m/$TAG{ul}/ ) {
                my $opt_str = (split / /, $line, 2)[1];
                if ( $opt_str ) {
                    map {
                        my ( $name, $val ) = split /=/, $_, 2;
                        $val =~ s/^" //x;
                        $val =~ s/ "$//x;
                        $opt{$name} = $val;
                    } $opt_str =~ m/ ( \w+ = (?: "[^"]*" | \w* ) ) /gx;
                }
            }
            else {
                push @sub_lines, $line;
            }

            LOOP_UL_LINES:
            while ( my $sub_line = <> ) {
                chomp $sub_line;
                if ( $sub_line !~ m/$TAG{ul_item}/ ) {
                    $line = $sub_line;
                    last LOOP_UL_LINES;
                }
                push @sub_lines, $sub_line;
            }
            print "\n", ul_markup(\%opt, @sub_lines);
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
    my ( $opt_ref, @lines ) = @_;

    my $effect  = $opt_ref->{effect} || q{};

    my $str;
    if ( $effect eq 'seq' ) {
        my $idx;
        $str .= ul_item_markup( $opt_ref, map('...', @lines) );
        $str .= ul_item_markup(
            $opt_ref,
            @lines[0 .. $idx++],
            map('...', $idx + 1 .. @lines)
        ) for @lines;
    }
    else {
        $str = ul_item_markup( $opt_ref, @lines );
    }

    return $str;
}

sub ul_item_markup {
    my ( $opt_ref, @lines ) = @_;

    my $subject = $opt_ref->{subject} || q{};

    @lines = map convert_escaped_char($_), @lines;
    my $concat_line = join "\n", map { s/$TAG{ul_item}//; "<li>$_</li>"; } @lines;
    my $str = <<"END_SECTION";
<div>
$subject
<ul>
$concat_line
</ul>
</div>
END_SECTION

    return $str;
}

sub normal_markup {
    my ( $line ) = @_;

    $line = convert_escaped_char( $line );

    my $str = <<"END_SECTION";
<div>
<h1>$line</h1>
</div>
END_SECTION

    return $str;
}

sub code_markup {
    my ( @lines ) = @_;

    @lines = map convert_escaped_char($_), @lines;
    my $concat_line = join q{}, @lines;
    chomp $concat_line;

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

    @lines = map convert_escaped_char($_), @lines;
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
