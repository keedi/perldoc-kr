#!/usr/bin/perl

use strict;
use warnings;
use MIME::Lite::TT::HTML;

die "Usage: $0 <email\@address.com>\n"
    unless @ARGV == 1;

my %params;

$params{email}  = shift;

my %options;
$options{INCLUDE_PATH} = '/home/saillinux/perl/';

my $msg = MIME::Lite::TT::HTML->new(
                                    From        =>  'korean.perl.workshop@gmail.com',
                                    To          =>  $params{email},
                                    Subject     =>  'Korean Perl Workshop 2008 등록 확인 전자우편 #3',
                                    Template    =>  {
                                                     text    =>  'kpw-regist.txt.tt',
                                                     html    =>  'kpw-regist.html.tt',
                                                    },
                                    TmplOptions =>  \%options,
                                    TmplParams  =>  \%params,
                                    Charset => 'utf8',
                                    Encoding => '8bit'
                                   );

$msg->send;
