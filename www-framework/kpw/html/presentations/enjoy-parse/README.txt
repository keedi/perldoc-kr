��ſ� �� ��� �����
=======================

���������̼� �ڷ� (���̾����������� ���� �����մϴ�.)

������ ȯ�濡�� ������ ���� �����Դϴ�.
���̺귯�� ������ ���縶.pm, �Ͼ�_�����.pm��
�����ڵ� ȯ���� �ƴϸ� �ε��� �� �����ϴ�.


*   ���� ���� ����Ʈ (srcs/)

    -   jeen-vs-whitecatz.pl
    -   ���縶.pm
    -   �Ͼ�_�����.pm
    -   image_syntax_highlight_emacs.dot


*   ������

    1.  cpan Parse::RecDescent ���� ���α׷��� �ʿ��� ����� ��ġ�մϴ�.
    2.  perl duckling.pl <- ���� #1
    3.  perl jeen-vs-whitecatz.pl  <- ���� #2


*   ���ǻ���

    ���縶.pm, �Ͼ�_�����.pm ���� ���丮�� �־���մϴ�.


*   emacs ���� ����

    �̸ƽ��� �ÿ��ߴ� �̹��� syntax highlight�� ������ ���ִ�
    �̸ƽ� ���� ���ϵ� ÷���մϴ�.  ���� �ÿ��� ����ߴ� ����ε�
    Ư�� keyword�� mummy, duck1, duck2, rune, $JEEN, $whitecatz��
    �Է½� �ƴϸ� �����ϸ� base64�� encoding�� �̹����� �̿��Ͽ�
    ����ߴ� ���ڿ��� ġȯ���ִ� �����Դϴ�.

    ���� ������ load ���ֽðų� .emacs ���Ͽ� �߰� ���ּ���.

    M-x extreme-perl-syntax-mode

    �ƴϸ� 

    (add-hook 'cperl-mode 'extreme-perl-syntax-mode-turn-on)

    pretty-lambda�� �����Ͽ� ���� �غ��ҽ��ϴ�.


