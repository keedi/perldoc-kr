package Soozy::Charset::Shift_JIS;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use base qw(Soozy::Charset);

use Jcode;

sub decode {
    my($self, $str) = @_;
    return Jcode->new($str, "sjis")->euc;
}

sub get_charset {
    return 'Shift_JIS';
}

sub output_filter {
    my($self, $contents) = @_;
    return Jcode->new($contents, 'euc')->sjis;
}
1;
