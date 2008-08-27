use utf8;
package 하얀_고양이;

use strict;
use warnings;
use Parse::RecDescent;

our @ISA = qw(Parse::RecDescent);

sub Parse::RecDescent::count { print "<하얀_냥>$_[0]\n" }

sub 교주님부활 {
  my ($self) = @_;
  my $parser = $self->SUPER::new(<<'하얀고양이법전');
{ 
  use Data::Dumper;
  binmode(STDOUT, ":utf8");

  my %meat_level = ("한단" => 1, "두단" => 2, "삼단" => 3, "사단" => 4,
		       "1" => "한단", "2" => "두단", "3" => "삼단", "4" => "사단" );
}

냐옹: 하얀고양이님스러운

하얀고양이님스러운: 카운터 /\Z/ { $item[1] }
		    | 뻘짓 /\Z/ { $item[1] }
                    | <error: 그런 대화는 없었습니다만...>

카운터: 카운터1 { "라면 먹고 얼굴 퉁퉁 배도 통통" }
	| 카운터2 { $item[1] }
	| 카운터3 { $item[1] }

카운터1: '라면 먹고 힘 짱짱'

카운터2: '사단고기' { '이제그만' }
         | /(.*)고기/ { $meat_level{$meat_level{$1} + 1} . "고기" }

카운터3: '이게 다 하얀_고양이님때문' { '음... 저를 탓하십시오' }
         | '&#$&"#$!"#!"$23534%$%#$%' { '@#$!@%@#$%@#$%@#$%' }

뻘짓: 뻘짓1 { "하악하악\n" }

뻘짓1: ( /\.{3,}/ | '이제그만' | /.*해보시자능/ )
하얀고양이법전

  return $parser;
}

1;
