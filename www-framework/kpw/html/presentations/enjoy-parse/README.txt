즐거운 펄 기억 남기기
=======================

프레젠테이션 자료 (파이어폭스에서만 열람 가능합니다.)

리눅스 환경에서 실행한 데모 파일입니다.
라이브러리 파일인 진사마.pm, 하얀_고양이.pm는
유니코드 환경이 아니면 로드할 수 없습니다.


*   예제 파일 리스트 (srcs/)

    -   jeen-vs-whitecatz.pl
    -   진사마.pm
    -   하얀_고양이.pm
    -   image_syntax_highlight_emacs.dot


*   실행방법

    1.  cpan Parse::RecDescent 으로 프로그램에 필요한 모듈을 설치합니다.
    2.  perl duckling.pl <- 데모 #1
    3.  perl jeen-vs-whitecatz.pl  <- 데모 #2


*   주의사항

    진사마.pm, 하얀_고양이.pm 같은 디렉토리에 있어야합니다.


*   emacs 관련 파일

    이맥스로 시연했던 이미지 syntax highlight를 가능케 해주는
    이맥스 설정 파일도 첨부합니다.  데모 시연에 사용했던 기능인데
    특정 keyword인 mummy, duck1, duck2, rune, $JEEN, $whitecatz를
    입력시 아니면 존재하면 base64로 encoding된 이미지를 이용하여
    언급했던 문자열을 치환해주는 설정입니다.

    설정 파일을 load 해주시거나 .emacs 파일에 추가 해주세요.

    M-x extreme-perl-syntax-mode

    아니면 

    (add-hook 'cperl-mode 'extreme-perl-syntax-mode-turn-on)

    pretty-lambda를 참조하여 급조 해보았습니다.


