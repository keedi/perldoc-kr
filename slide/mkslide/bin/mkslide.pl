#!/usr/bin/perl 

use 5.010;
use common::sense;
use YAML;
use Readonly;

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

    given ( $line ) {
        when ( /$TAG{code}/ ) {
            # 코드 태그 처리
            my @sub_lines;
            my $opt_str = (split / /, $line, 2)[1];
            my %opt = parse_options( $opt_str );

            if ( $opt{src} ) {
                open my $fh, $opt{src}
                    or do {
                        push @sub_lines, "Cannot open file [$opt{src}]:\n  $!";
                        print "\n", code_markup(\%opt, @sub_lines);
                        break;
                    };
                @sub_lines = <$fh>;
                close $fh;
                print "\n", code_markup(\%opt, @sub_lines);
                break;
            }

            LOOP_CODE_LINES:
            while ( my $sub_line = <> ) {
                last LOOP_CODE_LINES if $sub_line =~ m/$TAG{code}/;
                push @sub_lines, $sub_line;
            }
            print "\n", code_markup(\%opt, @sub_lines);
        };
        when ( /$TAG{text}/ ) {
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
        when ( /($TAG{ul})|($TAG{ul_item})/ ) {
            # 순서 없는 리스트 태그 처리
            my @sub_lines;
            my %opt;
            if ( $line =~ m/$TAG{ul}/ ) {
                my $opt_str = (split / /, $line, 2)[1];
                %opt = ( %opt, parse_options( $opt_str ) );
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
        when ( /$TAG{img}/ ) {
            # 이미지 태그 처리
            print "\n", img_markup($line);
        };
        default {
            # 기본
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
        $img_str = "<p>$name</p>\n"
                 . "<img src=\"$slide_info->{path}{images}/$file\" alt=\"$name\">"
                 ;
    }
    else {
        $img_str = "<img src=\"$slide_info->{path}{images}/$file\">";
    }

    my $str = "<div>\n"
            . "<p>\n"
            . "$img_str\n"
            . "</p>\n"
            . "</div>\n"
            ;

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

    my $subject = $opt_ref->{subject} ? "<p>$opt_ref->{subject}</p>" : q{};

    @lines = map convert_escaped_char($_), @lines;
    my $concat_line = join "\n", map { s/$TAG{ul_item}//; "<li>$_</li>"; } @lines;
    my $str = "<div>\n"
            . "$subject\n"
            . "<ul>\n"
            . "$concat_line\n"
            . "</ul>\n"
            . "</div>\n"
            ;

    return $str;
}

sub normal_markup {
    my ( $line ) = @_;

    $line = convert_escaped_char( $line );

    my $str = "<div>\n"
            . "<h1>$line</h1>\n"
            . "</div>\n"
            ;

    return $str;
}

sub code_markup {
    my ( $opt_ref, @lines ) = @_;

    my $effect  = $opt_ref->{effect} || q{};

    my $str;
    if ( $effect eq 'seq' ) {
        $str = effect_seq( \&code_item_markup, '#', $opt_ref, @lines );
    }
    else {
        $str = code_item_markup($opt_ref, @lines);
    }

    return $str;
}

sub effect_seq {
    my ( $func, $blank, $opt_ref, @lines ) = @_;

    my $idx;
    my $str;
    $str .= $func->( $opt_ref, map("$blank\n", @lines) );
    $str .= $func->(
        $opt_ref,
        @lines[0 .. $idx++],
        map("$blank\n", $idx + 1 .. @lines)
    ) for @lines;

    return $str;
}

sub code_item_markup {
    my ( $opt_ref, @lines ) = @_;

    my $subject = $opt_ref->{subject} ? "<p>$opt_ref->{subject}</p>" : q{};

    @lines = map convert_escaped_char($_), @lines;
    my $concat_line = join q{}, @lines;
    chomp $concat_line;

    my $str = "<div>\n"
            . "$subject\n"
            . "<pre>\n"
            . "$concat_line\n"
            . "</pre>\n"
            . "</div>\n"
            ;

    return $str;
}

sub text_markup {
    my ( @lines ) = @_;

    @lines = map convert_escaped_char($_) || q{}, @lines;
    my $concat_line = join "<br>\n", @lines;

    my $str = "<div>\n"
            . "<p>\n"
            . "$concat_line\n"
            . "</p>\n"
            . "</div>\n"
            ;

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

sub parse_options {
    my $opt_str = shift;

    return unless $opt_str;

    my %opt;
    map {
        my ( $name, $val ) = split /=/, $_, 2;

        $name =~ s/^\s+ //x;
        $name =~ s/ \s+$//x;

        $val =~ s/^" //x;
        $val =~ s/ "$//x;

        $name = $name eq '제목' ? 'subject'
              : $name eq '효과' ? 'effect'
              : $name eq '파일' ? 'src'
              : $name
              ;
        $opt{$name} = $val;
    } $opt_str =~ m/ ( .+? = (?: "[^"]*" | \w* ) ) /gx;

    return %opt;
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
<td nowrap align="left"><a href="javascript:slide.prev()">prev</a></td>
<td width="100%"></td>
<td nowrap align="right">Page
<input id="pagenum" type="text" size="2" value="0"
onkeyup="slide.go(\$('pagenum').value)" onclick="\$('pagenum').select()">
 / <span id="maxnum"></span>
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
###COMPANY###
</p>
<p>
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
