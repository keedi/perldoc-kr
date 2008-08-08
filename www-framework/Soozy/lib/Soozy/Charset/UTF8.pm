package Soozy::Charset::UTF8;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use base qw(Soozy::Charset);

use Jcode;

sub decode {
    my($self, $str) = @_;
    return Jcode->new($str, "utf8")->euc;
}

sub get_charset {
    return 'UTF-8';
}

sub output_filter {
    my($self, $contents) = @_;
    return Jcode->new($contents, 'euc')->utf8;
}
1;
