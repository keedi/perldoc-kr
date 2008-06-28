function $(id){ return document.getElementById(id) }

function Slide(frame, screen, slides, pagenum, translate){
    var cur  = 0;
    var max  = 0;
    var e2j  = new Translator();
    this.init = function(){
        var elems = $(slides).childNodes;
        for (var i = 0; i < elems.length; i++){
            if (elems[i].nodeType != 1) continue;
            elems[i].id = '.slide' + max++;
        }
        $(frame).width  = '100%'; // window.innerWidth;
        $(frame).height = window.innerHeight;
        this.go(0);
    };
    this.go = function(page){
        if (page != undefined) cur = page;
        if ($(translate).checked) e2j.cancel();
        e2j.cancel();
        $(screen).innerHTML = $('.slide' + cur).innerHTML;
        if ($(pagenum)) $(pagenum).value = cur;
        if ($(translate).checked) {
            var text = $(screen).innerHTML.replace(/\n/g,'');
            text = text.replace(/<pre>.*<\/pre>/g, '');
            text = text.replace(/<.*?>/g, '');
            if (text) e2j.translate(text, $(screen));
        }
    }
    this.next = function(){
        if (++cur >= max) cur = 0;
        this.go(cur);
    };
    this.prev = function(){
        if (--cur < 0) cur = max - 1;
        this.go(cur);
    };
    this.home = function(){
        this.go(0);
    };
    this.end = function(){
        this.go(max - 1);
    };
    return this;
}

function Translator(){
    var proxy = './e2j.cgi';
    var xmlhttp;
    try{
        xmlhttp = new XMLHttpRequest();
    }catch(e){
        xmlhttp = new new ActiveXObject ("Microsoft.XMLHTTP");
    }
    this.translate = function(string, element) {
        if (! xmlhttp) return;        
        xmlhttp.onreadystatechange = function(){
            if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
                var txt = xmlhttp.responseText;
                element.innerHTML +=
                    '<p clatxss="translated">('
                    + txt +
                    ')</p>';
            }
        }
        xmlhttp.open('POST', proxy , true);
        xmlhttp.setRequestHeader(
            "Content-Type", 
             "application/x-www-form-urlencoded"
        );
        xmlhttp.send('q=' + escape(string) + '\n');
    }
    this.cancel = function(){
        if (xmlhttp.readyState == 0 || xmlhttp.readyState == 4) return;
        xmlhttp.abort();
    }
    return this;
}

var slide = new Slide('frame', 'screen', 'slides', 'pagenum', 'translate');

window.onload = function(e){
    slide.init()
}

window.onkeydown = function(e){
    switch(e.keyCode){
        case 35:  // End
        case 221: // ']'
            { slide.end(); break; }
        case 36:  // Home
        case 219: // '['
            { slide.home(); break; }
        case 37: // Left Arrow
            { slide.prev(); break; }
        case 39: // Right Arrow
            { slide.next(); break; }
    }
}
