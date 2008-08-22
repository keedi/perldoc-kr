function $(id){ return document.getElementById(id) }

function Slide(frame, screen, slides, pagenum){
    var cur  = 0;
    var max  = 0;
    this.init = function(){
        var elems = $(slides).childNodes;
        for (var i = 0; i < elems.length; i++){
            if (elems[i].nodeType != 1) continue;
            elems[i].id = '.slide' + max++;
        }
        $(frame).width  = '100%'; // window.innerWidth;
        $(frame).height = window.innerHeight;
        $(maxnum).innerHTML = max;
        this.go(0);
    };
    this.go = function(page){
        if (page != undefined) cur = page;
        $(screen).innerHTML = $('.slide' + cur).innerHTML;
        if ($(pagenum)) $(pagenum).value = cur;
    }
    this.next = function(step){
        step ? cur += step : ++cur;
        if (cur >= max) cur = 0;
        this.go(cur);
    };
    this.prev = function(step){
        step ? cur -= step : --cur;
        if (cur < 0) cur = max - 1;
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

var slide = new Slide('frame', 'screen', 'slides', 'pagenum');

window.onload = function(e){
    slide.init()
}

window.onkeydown = function(e){
    switch(e.keyCode){
        case 35:  // End
            { slide.end(); break; }
        case 36:  // Home
            { slide.home(); break; }
        case 221: // ']'
            { slide.next(5); break; }
        case 219: // '['
            { slide.prev(5); break; }
        case 37: // Left Arrow
            { slide.prev(); break; }
        case 39: // Right Arrow
            { slide.next(); break; }
    }
}
