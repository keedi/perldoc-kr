use utf8;
package 진사마;

use strict;
use warnings;
use Parse::RecDescent;

our @ISA = qw(Parse::RecDescent);

our @quotes = (
               "라면 먹고 힘 짱짱",
               "한단고기",
               "이게 다 하얀_고양이님때문",
              );

sub Parse::RecDescent::뻘짓랜덤 { $_[int rand @_] }

sub 하아악커 {
  my ($self) = @_;

  my $parser = $self->SUPER::new(<<'진님말빨');
{ 
  use Data::Dumper;
  binmode(STDOUT, ":utf8");
  my %meat_level = ("한단" => 1, "두단" => 2, "삼단" => 3, "사단" => 4,
		       "1" => "한단", "2" => "두단", "3" => "삼단", "4" => "사단" );
}

아왜욤: 진님스러운

진님스러운: 뻘짓 /\Z/ { $item[1] }
	    | 뭥미 /\Z/  { $item[1] }
	    | 대연합하얀고양이 /\Z/ { $item[1] }
	    | <error: 아 왜욤! 한번 해보시겠다능?>

뻘짓: 뻘짓1 { 뻘짓랜덤(@진사마::quotes) }

뻘짓1: ('하악하악' | '이제그만')

대연합하얀고양이: 연합1 { $item[1] }
		  | 연합2 { $item[1] }

연합1: '사단고기' { "이제그만\n" }
       | /(.*)고기/ { $meat_level{$meat_level{$1} + 1} . "고기" }

연합2: /.*탓하십시오/ { '&#$&"#$!"#!"$23534%$%#$%' }
       | '@#$!@%@#$%@#$%@#$%' { "오호라.. 한번 해보시자능\n" }

뭥미: 뭥미1 { "...\n" }

뭥미1: '라면 먹고 얼굴 퉁퉁 배도 통통'

진님말빨

  return $parser;
}

1;
