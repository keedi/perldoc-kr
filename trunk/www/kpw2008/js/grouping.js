/*
 * Ext JS Library 2.1
 * Copyright(c) 2006-2008, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://extjs.com/license
 */

Ext.onReady(function(){

    Ext.QuickTips.init();
    
    var xg = Ext.grid;

    // shared reader
    var reader = new Ext.data.ArrayReader({}, [
        {name: 'subject'},
        {name: 'speaker'},
        /* {name: 'datetime', type: 'date', dateFormat: 'n/j h:ia'}, */
        {name: 'period'},
        {name: 'type'},
        {name: 'desc'}
    ]);

    var gview = new Ext.grid.GroupingView({
        forceFit:true,
        scrollOffset: 0,
        startCollapsed: false,
        groupTextTpl: '{text} ({[values.rs.length]} {[values.rs.length > 1 ? "Items" : "Item"]})',
        enableRowBody: true,
        getRowClass : function(record, rowIndex, p, store) {
            p.body = '<table style="padding: 3px;margin: 5px;width:595px;display:table;border-collapse:collapse;border-bottom:1px solid #99BBE8;border-top:1px solid #99BBE8"><tr><td width="15%" align="center" rowspan="2" style="border-right:1px solid #99BBE8;vertical-align: middle"><b>' + record.data.period + '</b></td><td style="border-bottom: 1px solid #99BBE8;padding: 3px" width="65%"><b>' + record.data.subject + '</b></td><td style="padding:3px;border-bottom: 1px solid #99BBE8;border-left:1px solid #99BBE8" width="20%">' + record.data.speaker + '</td></tr><tr><td colspan="2"><div style="width:100%;padding:3px">' + record.data.desc + '</div></td></tr></table>';
            return 'x-grid3-row-expanded';
        }
    });


    var grid = new xg.GridPanel({
        store: new Ext.data.GroupingStore({
            data: xg.dummyData,
            sortInfo:{field: 'period', direction: "ASC"},
            reader: reader,
            groupField:'type'
        }),
        
        columns: [

            {
                header: "발표 시간",
                hidden: true,
                width: 20,
                sortable: false,
                dataIndex: 'period',
                renderer: function(value, p, record) {
                    return String.format(
                        '<div class="topic"><b>{0}</b></div>',
                        value
                    );
                }
            },
            {
                id:'subject',
                header: "주제",
                width: 60,
                hidden: true,
                sortable: false,
                dataIndex: 'subject',
                renderer: function(value, p, record) {
                    return String.format(
                        '<div class="topic"><b>{0}</b><br /><span class="author">{1}</span></div>',
                        value, record.data.speaker
                    );
                }
            },
            {header: "발표자", hidden: true, width: 20, sortable: false, dataIndex: 'speaker'},
            {header: "발표형식", width: 20, hidden: true, sortable: true, dataIndex: 'type'}
        ],
        hideHeaders:true,
        view: gview,
        autoHeight: true,
        frame:true,
        width: 628,
        height: 600,
        collapsible: true,
        animCollapse: false,
        title: 'Workshop Schedule ',
        iconCls: 'icon-grid',
        renderTo: 'group-grid'
    });
});


// Array data for the grids
Ext.grid.dummyData = [
    ['Prologue','김도형','13:00 ~ 13:10', '0. 시작하며 (Prologue)','시작하며...'],
    [
      '최신 스타일 Perl로 개과천선하기',
      '강차훈',
      '13:10 ~ 13:30',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      '역 사가 긴 Perl 특성상 과거의 오래된 자료와 서적이 많아 사용자들이 철 지난 자료를 기준으로 공부하는 경우가 흔하다. Perl이 그간 많은 버전업을 거치며 발전해 왔음에도 대부분의 사용자들은 새로운 특징을 잘 모르고 과거 방식으로 Perl 코드를 작성한다.  Perl의 최신 경향과 스타일을 살펴봄으로써 이제는 Old Perl에서 탈출하도록 하자!'
    ],
    [
      'Perl Basic Skill Up',
      '전종필',
      '13:30 ~ 13:50',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      'Perl 기술을 향상시키고 현업에 적용하기 위해서는 "무엇"을 "어떻게" 활용해야 할지를 개인적인 경험에 비추어 제시한다. 이제 막 Perl에 발을 들이고 재미를 느끼는 사람들, 팀원들에게 Perl을 배우게 하려는 사람들, 기술적 답보상태에서 돌파구를 찾으려는 사람들에게 도움이 될만한 방향제시가 되었으면 한다. 유연성, Regex, Reference, Package(모듈, 객체), CPAN 등에 대한 총론을 제공한다.'
    ],
    [
      'Location Prediction for Indoor Sensor Networks',
      '김동민',
      '14:00 ~ 14:20',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      '본 발표에서는 Perl을 이용한 프로토타입 개발에 대하여 살펴본다. 위치예측은 인텔리전트 빌딩이나 스마트 홈 네트워크를 구축하기 위한 기반 기술 중 하나이다. 위치예측에 관한 많은 연구들이 수행되어 왔지만 대부분의 연구는 단일 이동체의 위치 예측에 중점을 두고 있다. 보다 실용적인 연구를 위하여 다수의 이동체가 동시에 이동하는 경우를 고려한 알고리즘을 고안하였다. 알고리즘의 실효성을 검증하기 위하여 단순히 컴퓨터 시뮬레이션만 하는 것이 아니라 실제 테스트베드를 구축하여 실험을 해야 했다. 센서네트워크를 구축하여 이동체의 이동 정보를 인식하고 실시간으로 정보수집서버로 전달하여 위치예측을 수행한다. Perl을 이용하여 빠르게 알고리즘의 프로토타입을 구현하여 테스트베드를 구축할 수 있었다.'
    ],
    [
      'Web2RSS with Perl',
      '김기석',
      '14:30 ~ 14:50',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      '자신이 자주가는 웹페이지가 Feed를 제공하지 않는 경우를 종종 경험했을 것이다. 그런 Feed를 제공하지 않는 웹페이지의 변경 사항을  Perl을 이용하여 RSS Feed로 만들어 본다.  그 과정에서 Perl의 정규표현식으로 문서의 원하는 부분을 가져 오기, LWP모듈로 웹페이지 가져오기,  DBM해시를 이용해서 정보를 저장하기 등의 방법을 알아본다.'
    ],
    [
      'Introduction to Catalyst for Rapid Web Development',
      '한송희',
      '15:00 ~ 15:20',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      '웹 프레임워크는 보다 효율적으로 웹어플리케이션을 개발하기 위한 구조이다. 주로 MVC(Model-View-Controller)의 패턴으로 되어 있으며, 많은 언어에서 많은 종류의 웹프레임워크가 개발되었고 이용되고 있다. 카탈리스트는 펄로 만들어지 웹프레임워크 중 하나이다.  2005년 펄 채널을 중심으로 처음 만들어진 이후, 점점 더 그 규모커졌고 안정적으로 메인테인 되고 있으며, 실질적인 업무에서도 사용되고 있다. 이 세션에서는 아직 국내에서는 많이 알려지지는 않은 카탈리스트의 사용법과 함께, 카탈리스트 내부 동작에 관해서도 간단하게 설명하고자 한다.'
    ],
    [
      'Gtk2-Perl을 사용한 크로스 플랫폼 GUI 환경',
      '김도형',
      '15:30 ~ 15:50',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      'GUI 환경은 더이상 커맨드 라인을 사용하지 못하는 사용자만을 위한 인터페이스가 아니다. 어떠한 프로그램이라도 GUI를 제공하지 않고서는 사용자에게 친숙하게 다가가기 어렵다. Gnome 데스크탑의 핵심 기술인 Gtk2는 리눅스 뿐만 아니라 윈도우즈, 맥킨토시등 다양한 환경의 GUI 개발을 가능케하는 대표적인 오픈소스 크로스 플랫폼 GUI 라이브러리다. 또한 Gtk2는 C로 작성했음에도 불구하고, Perl, Python, Ruby 등 다양한 스크립트 언어로 바인딩되어 있으며, 현존하는 그래픽 라이브러리 중 가장 많은 언어를 지원하는 것이 특징이다. Gtk2-Perl 바인딩을 이용하면 미려한 GUI를 가진 프로그램을 경쾌한 템포로 작성할 수 있다. Gtk2 와 Perl을 이용해서 이식성이 뛰어난 GUI 응용을 작성하는 법을 알아본다.'
    ],
    [
      '생물학을 위한 Perl',
      '박민영',
      '16:00 ~ 16:20',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      '전산적인 지식이 없는 생물학자와 beginner bioinformatician을 위한 활용 가이드. 생물학적 실험 데이터가 점점 증가하게 됨에 따라 의미있는 데이터를 얻기 위해 대용량 데이터를 다루는 것은 필수적이다. 이러한 작업을 Perl의 BioPerl library를 사용함으로써 간편하게 처리할 수 있다. 문서를 통해 Perl로 어떤 작업을 할 수 있으며 그 활용방법은 무엇인지 알아본다.'
    ],
    [
      'Bioperl: The biological module of Perl language',
      '박종화 박사',
      '16:30 ~ 17:00',
      '1. 정규 발표 1부 (Regular Talk, Part #1)',
      'Bioperl is the first biological perl programming module developed in MRC centre, Cambridge, UK in 1994. It is one of the most successful modules in Perl. It was started as a comprehensive library and objects for bioinformatics. It supports an openfree exchange of sources and information in science. Its original philosophy, approach, and Bioperl.pl libraray is introduced.'
    ],
    [
      '저녁 식사',
      '다함께',
      '17:00 ~ 17:30',
      '2. 휴식 (Rest)',
      '맛있는 샌드위치를... :-)'
    ],
    [
      'Perl & Security Community - 보안에서 Perl 의 위치',
      '배상우',
      '17:30 ~ 17:50',
      '3. 정규 발표 2부 (Regular Talk, Part #2)',
      '오늘날의 보안 담당자는 네트워크, 서버, 어플리케이션, DB 등 다양한 분야의 전문지식을 지녀야한다. 이런 상황에서 Perl은 쉬운 문법과 CPAN의 풍부한 모듈 및 예제, 뛰어난 문자열 처리 능력, 시스템 호환성을 지니고 있어 보안 업무의 생산성을 높이는데 기여하고 있다. 실제로 국내외 보안 커뮤니티에서 Perl은 C/C++, Assembly 언어와 함께 중요한 위치를 차지하고 있으며, 많은 해킹툴과 보안툴이 Perl로 개발되고 있다. 그러나 보안관련 이해당사자 상당수가 Perl에 대한 잘못된 편견을 가지고 있어 실무 도입을 꺼리고 있다. 국내외 보안커뮤니티에서 다양하게 Perl을 활용하는 사례를 살펴봄으로써, 보다 많은 이들이 Perl을 통해 업무 생산성 향상을 경험할 수 있도록 돕는다.'
    ],
    [
      '해커를 위한 Perl - Perl로 만든 익스플로잇 코드 살펴보기',
      '권혁진',
      '18:00 ~ 18:20',
      '3. 정규 발표 2부 (Regular Talk, Part #2)',
      '해 커들은 Perl을 어떻게 사용할까? 해커들은 시스템의 취약점 발표와 함께 그것을 증명할 수 있는 익스플로잇 코드를 만든다. 익스플로잇은 서비스 거부 공격, 원격 명령어 실행, 버퍼 오버플로우 공격 등 그 주제가 다양하다. 또한 해커들은 그것을 구현하기 위해 수단, 방법을 가리지 않는다. 그렇다면 Perl로 만들어진 익스플로잇에는 어떤 것들이 있는지 알아보고 동작 과정을 분석한다.'
    ],
    [
      '언어학을 위한 Perl',
      '김준홍',
      '18:30 ~ 18:50',
      '3. 정규 발표 2부 (Regular Talk, Part #2)',
      'Perl 은 유연하고도 강력한 여러 기능, 특히 언어 내부에 포함된 정규표현식의 처리 능력 덕분에 문서 처리에 뛰어난 능력을 발휘한다. 이에 언어처리 관련 분야(NLP:Natural Langua Processing, IR: Inforamion Retrival)에서는 일찍부터 Perl을 활용했다. 본 발표에서는 한국어 정보처리 특히 2000년경 명사추출기 구현 프로젝트를 중심 예로 삼아 Perl의 활용을 설명한다. 또한, 과거에서 현재로 넘어오며 달라진 여러 IT환경에 따른 새로운 방법론과 고민거리에 대해서도 잠시 시간을 할애할 예정이다.'
    ],
    [
      'Perl 을 이용한 영상 오브젝트 추출',
      '김현승',
      '19:00 ~ 19:20',
      '3. 정규 발표 2부 (Regular Talk, Part #2)',
      '동영상의 저작권 침해여부를 확인하기 위해서는 동영상을 재생하거나 썸네일 이미지를 모두 확인해야한다. 동영상의 썸네일을 이용하여 로고를 추출할 수 있다면 확인작업에 소요되는 시간을 줄이고, 정확성을 향상시킬수 있다. IPA 와 ImageMagicK 모듈을 활용하여 perl로 구현하는 과정을 살펴본다.'
    ],
    [
      '즐거운 Perl 기억 남기기 - Parse::RecDescent',
      '김희원',
      '19:30 ~ 19:50',
      '3. 정규 발표 2부 (Regular Talk, Part #2)',
      '문자열을 정교하게 처리하는 CPAN의 많은 모듈은 구조적으로 문자열을 다루기 위해서 파서 모듈을 사용한다. 이 중에서 Perl 커뮤니티를 이끄는 원로 중 한 명인 Damian Conway가 작성한 Parse::RecDescent 파서는 그 강력함 때문에 많은 이들에게 사랑받고 있다. Parse::RecDescent 모듈이 Top-Down Recursive Descent 파서임을 소개하는 것을 뛰어넘어 새로운 개념의 프로그램을 작성할 수 있음을 보인다. Perl IRC 채널에서 대화내용을 분류해서 보여주는 작업을 예로들어 실제로 이 모듈을 적용하는 방법도 설명한다.'
    ],
    [
      '지리정보 시스템(GIS)을 위한 Perl',
      '김건호',
      '20:00 ~ 20:05',
      '4. 짧은 발표 (Lightening Talk)',
      'GIS(지리정보시스템)는 지리공간 데이터를 분석·가공하여 교통·통신 등과 같은 지형 관련 분야에 활용할 수 있는 시스템이다. 네비게이션과 Google Map/Earth는 GIS 분야 중 가장 널리 알려진 대표적인 성과물이다. GIS 작업은 다양한 포멧의 대용량 데이터를 다뤄야한다. 더불어 최근에는 GML/KML등의 XML 기반 자료로의 변환도 필요하다. Perl은 GIS분야가 아니더라도 이런 작업에 강점을 가지고 있다. GIS분야에서 대용량 데이터 변환, 가공, 분석에 Perl을 어떻게 활용할 수 있는지 소개한다.'
    ],
    [
      'Practical Extraction and Report for NS2',
      '김동민',
      '20:05 ~ 20:10',
      '4. 짧은 발표 (Lightening Talk)',
      '대표적인 네트워크 시뮬레이션툴 NS2의 출력파일인 트레이스 파일은 칼럼으로 구분되어 각종 정보가 기록되어 있다. perl을 이용하여 이 파일에서 throughput, delay 등 유용한 정보를 추출(extraction)하고 그래프를 얻기 위해 결과물을 정리(report)하는 방법에 대해서 알아본다.'
    ],
    [
      '당신은 이미 Perl 하고 있다 - 소스필터를 이용한 몰래 Perl 시키기',
      '김희원',
      '20:10 ~ 20:15',
      '4. 짧은 발표 (Lightening Talk)',
      '소스 필터는 Perl 프로그램 텍스트를 Perl이 해석하기 전에 먼저 변경한다. 이것은 C의 전처리기가 C 프로그램 텍스트를 컴파일러가 처리하기 전에 먼저 변경하는 것과 유사하다. CPAN의 소스 필터 모듈을 이용하면 놀라울 정도로 쉽게 새로운 언어를 Perl로 구현하고 실행할 수 있다. 자신이 작성한 언어를 이용해 주위 동료들이나 친구, 가족, 상사까지 몰래 Perl을 사용하게 해보자.'
    ],
    [
      'RSS 번역기 만들기',
      '강차훈',
      '20:15 ~ 20:20',
      '4. 짧은 발표 (Lightening Talk)',
      '다양한 CPAN 모듈을 이용하면 원하는 바를 빠르게 구현할 수 있다. CPAN모듈을 사용해 RSS번역기를 쉽고 빠르게 만들어보자.'
    ],
    [
      'The Secret of Class::Data::Inheritable',
      '한송희',
      '20:20 ~ 20:25',
      '4. 짧은 발표 (Lightening Talk)',
      'Class::Data::Inheritable 모듈은 Perl에서 간단하게 클래스를 상속하기 위해 만들어졌다. 이 모듈의 코드는 굉장히 짧지만 그 안에서 Perl의 강력한 기능을 사용해 OOP를 구현하고 있다. OOP 그 자체에 대한 내용 보다는 Class::Data::Inheritable에서 사용한 다양한 기법을 코드 분석을 통해 습득하는 데 집중한다.'
    ],
    [
      'Javascript as Mini-lang on Perl',
      '김현승',
      '20:25 ~ 20:30',
      '4. 짧은 발표 (Lightening Talk)',
      'Javascript::Spidermonkey는 ECMA 스크립트 엔진인 SpiderMonkey를 Perl로 래핑한 CPAN 모듈이다. Javascript::Spidermonkey 모듈을 이용해서 Perl로 구현한 함수의 제어처리를 Javascript가 맡도록 위임하는 과정을 살펴본다.'
    ],
    ['Epilogue','김도형','20:30 ~ 20:50', '9. 정리하며 (Epilogue)','정리하며...']
];

