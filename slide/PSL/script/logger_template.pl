#!/usr/bin/perl
use strict;
use warnings;

my $home_dir = $ENV{'HOME'};
my $report_dir = $home_dir.'/work/report/';
my $new_report_dir = $home_dir.'/work/new_report/';


my $template_file = 'report_template3.tsp';

# a compiled list of regular expression list
# report_code line
my $regex_rpt = qr{\$report_code\s*=\s*["']\d*["']\s*;};

# elminate inc_reportHeader
my $regex_header = qr{include.+inc_reportHeader\.tsp.+\n};

# elminate inc_reportFooter
# my $regex_footer = qr{<?.+include.+inc_reportFooter\.tsp.+\n};

# remove irritating comments
my $regex_comments = qr{\/\/\s*(리포트 코드번호|REPORT 시작)\n};)}

# remove make_header
my $regex_make_header = qr{.*make_header.*\n};

my $report_template = ''; # report template string

{
  local $/;
  open my $fd_template, '+<', $template_file
    or die "Couldn't open such template file: $!";

  $report_template = <$fd_template>;

  close $fd_template;
}

opendir (my $rdir, $report_dir) or die "No such dir to open: $!";

foreach my $logger_file (readdir($rdir)) {
    next if $logger_file !~ /^trk\w*_.*\.tsp$/;
    next if $logger_file =~ /.*ajax.*/;
    next if $logger_file =~ /^trkpopup\w*\.tsp$/;
    next if $logger_file =~ /^trk_(doc|excel|csv|html).*/;

    my $report_file = $new_report_dir.$logger_file;

    $logger_file = $report_dir.$logger_file;

    my $report_src = $report_template;
    my $report_code_line = '';

    # a report file I am gonna write to
    open my $fd_report, '>', $report_file
        or die "Couldn't create such report file: $!";

    # a report file I am reading from
    open my $fd_logger, '<', $logger_file
      or die "Couldn't open such logger file: $!";

    # slurp the whole thing '-');;
    my $logger_src = do { local $/; <$fd_logger> };

    # remove header include line
    $logger_src =~ s/<\?(.+?)$regex_header/<\?/s;

    # make sure to save lines before the header include
    my $header_frag = $1;

    # trim off what we dont want
    $logger_src =~ s/$regex_header//;
    # $logger_src =~ s/$regex_footer//;
    # $logger_src =~ s/\/report/\/report_2008/g;
    # $logger_src =~ s/\/report/\/report_2008/g;
    $logger_src =~ s/inc_reportFooter\.tsp/report_footer\.inc/;
    $logger_src =~ s/\$DOCUMENT_ROOT\.\"\/report\//\"/g;

    # $logger_src =~ s/$regex_rpt// and $report_code_line = $&;
    $logger_src =~ s/$regex_comments//g;
    # $logger_src =~ s/$regex_make_header//;


    # prepend report_code declaration to the report_template
    $report_src =~ s/<\?/<\?\n\t$header_frag\n/;

    my $contents =<<REPORT;
$report_src
$logger_src
REPORT

    print $fd_report $contents;
    close $fd_report;
    close $fd_logger;
}

closedir($rdir);

exit;
