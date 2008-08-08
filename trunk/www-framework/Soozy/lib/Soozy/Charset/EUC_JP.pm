package Soozy::Charset::EUC_JP;
use vars qw($VERSION);
$VERSION = 0.01;

use strict;
use base qw(Soozy::Charset);

use Jcode;

sub get_charset {
    return 'euc-jp';
}
1;
