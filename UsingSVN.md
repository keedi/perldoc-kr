번역의 편리를 위해 영어와 일본어 perldoc이 svn에 포함되어 있기때문에 체크아웃 속도가 느릴 수 있습니다.


각 언어의 perldoc은 /perldoc/ko,en,jr 아래에 있기때문에 간단히 한글문서에 대해서만 작업하시려면


```
svn checkout http://perldoc-kr.googlecode.com/svn/trunk/perldoc/ko/5.10 perldoc-ko-5.10
svn checkout https://perldoc-kr.googlecode.com/svn/trunk/perldoc/ko/5.10 perldoc-kr --username pung96
```
를 사용하시면 됩니다.