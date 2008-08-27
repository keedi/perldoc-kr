#!/usr/bin/perl
use strict;
use warnings;

use Parse::RecDescent;

my $parser = Parse::RecDescent->new(<<'DUCK');

DuckTrain : Mummy Ducklings EOF
         | Mummy Ducklings Ugly EOF
         | Mummy Ducklings Ugly Ducklings EOF
         | Ducklings Mummy EOF
         | Ugly Ducklings Mummy EOF
         | Ducklings Ugly Ducklings Mummy EOF

Ducklings   : Duckling Ducklings | Duckling

Mummy    : 'mummy'

Duckling    : 'duck1' | 'duck2'

Ugly     : 'rune'

EOF      : /\Z/
DUCK


my $duckling1 = "mummy duck1 rune duck2 duck1";

my $duckling2 = "duck1 duck2 rune mummy";

print defined $parser->DuckTrain($duckling1) ?
  "맛있어 보이는 오리행렬\n" : "이건 뭥미...";

print defined $parser->DuckTrain($duckling2) ?
  "맛있어 보이는 오리행렬\n" : "이건 뭥미..." , "\n";

