# Something to difficult translation

# Introduction #

perlop.pod 작업 중에 번역이 아리송한 것들에 대해서 이렇게 몇 가지 추가합니다.
물론 앞으로 추가 될 예정입니다.
(이 Wiki사용법에 대해서는 적응이 안되어 있어서, 양해를 부탁드리겠습니다)


# Details #

**quoute  and quote-like operator(인용 과 인용같은 연산자 :: 도저히 답이 안나오는)** return value (일단 반환값이라고 썼는데.... 리턴값이 좋을 지... 뭐가 좋을 지에 대한 고민중입니다)
**context ( // If the right operand is zero or negative, it returns an empty string or an empty list, depending on the context. ) (스칼라 컨텍스트, 리스트 컨텍스트 그대로 사용하고 있습니다, 마찬가지로 답이 안나오더군요 ㅠ**ㅠ)** In scalar context, ".." returns a boolean value. (흠...)
**literal values (While we usually think of quotes as literal values,) // 그대로 리터럴 값으로 사용하고 있습니다** delimiter ( In the following table, a C<{}> represents any pair of delimiters you choose.  ) // 뭔가 안떠오릅니다
_escape ( The following escape sequences are available in constructs that interpolate  and in transliterations. ) // 쿨럭쿨럭.. 그대로 이스케이프 씁니다 ㅠ_ㅠ**

> 이미 많이 사용하고 있는 표준의 전산 용어를 사용하는 것은 어떨까요? :-)

  * quote and quote-like operator 는 따옴표와 따옴표 같은 연산자
  * return value: 반환 값은 많이 사용하는 전산 용어입니다.
  * context: 문맥 역시 많이 사용하는 전산 용어입니다.
  * literal: 상수 (constant와 함께 많이 사용하는 것으로 기억합니다만...)
  * escape sequence: 확장열 또는 확장 문자열

> -keedi



흠.. 현재는 이정도 입니다.

그외에 개행문자 -> 줄바꿈 문자, 참고해주세요(참조해주세요와 헷갈)...
뭐랄까, 일본어를 바탕으로 번역하다보니까, 여러모로 저도모르게 일본어식 한글 사용이 잦음을 인식하고 있습니다. (예 : 할 수 있습니다. -> 하는 것이 가능합니다 등등..)
이에 대해서는 일단 가볍게 일본어 부분을 살짝 번역해놓고 영어로 관련부분을 한번 더 봐야하겠죠.
물론 많은 사람들이 참여해서 피드백이 가능하겠다면 좋겠지만.. 흐...
모두 힘을 내어서 열심히/즐겁게 작업했으면 좋겠습니다.