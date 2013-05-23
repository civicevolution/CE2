//These are some extra functions that might be needed, see below




// Create a safe reference to the Underscore object for use below.
var _ = function(obj) {
    if (obj instanceof _) return obj;
    if (!(this instanceof _)) return new _(obj);
    this._wrapped = obj;
};

// this is used along with throttle in the mousemove method of the rating directive
function _pd(fn) {
    return function(e) {
        //(e.preventDefault) ? e.preventDefault() : e.returnValue = false;
        fn.apply(this, arguments);
    }
}
//used in mousemove for rating
// Returns a function, that, when invoked, will only be triggered at most once
// during a given window of time.
_.throttle = function(func, wait, immediate) {
    var context, args, timeout, result;
    var previous = 0;
    var later = function() {
        previous = new Date;
        timeout = null;
        result = func.apply(context, args);
    };
    return function() {
        var now = new Date;
        if (!previous && immediate === false) previous = now;
        var remaining = wait - (now - previous);
        context = this;
        args = arguments;
        if (remaining <= 0) {
            clearTimeout(timeout);
            timeout = null;
            previous = now;
            result = func.apply(context, args);
        } else if (!timeout) {
            timeout = setTimeout(later, remaining);
        }
        return result;
    };
};

// In rating I need to know the offset and width of the rating bar
_.offset = function(elm) {
    try {return elm.offset();} catch(e) {}
    var rawDom = elm[0] || elm;
    var _x = 0;
    var _y = 0;
    var body = document.documentElement || document.body;
    var scrollX = window.pageXOffset || body.scrollLeft;
    var scrollY = window.pageYOffset || body.scrollTop;
    _x = rawDom.getBoundingClientRect().left + scrollX;
    _y = rawDom.getBoundingClientRect().top + scrollY;
    return { left: _x, top:_y };
}

// In rating I need to know the offset and width of the rating bar
_.width = function(elm) {
    if (typeof elm.clip !== "undefined") {
        return elm.clip.width;
    } else {
        if (elm.style.pixelWidth) {
            return elm.style.pixelWidth;
        } else {
            return elm.offsetWidth;
        }
    }
};


// IE8 cannot create a new date from ISO date string, this fixes that problem
(function(){
    var D= new Date('2011-06-02T09:34:29+02:00');
    if(isNaN(D) || D.getUTCMonth()!== 5 || D.getUTCDate()!== 2 ||
        D.getUTCHours()!== 7 || D.getUTCMinutes()!== 34){
        Date.fromISO= function(s){
            var day, tz,
                rx=/^(\d{4}\-\d\d\-\d\d([tT][\d:\.]*)?)([zZ]|([+\-])(\d\d):(\d\d))?$/,
                p= rx.exec(s) || [];
            if(p[1]){
                day= p[1].split(/\D/);
                for(var i=0,L=day.length;i<L;i++){
                    day[i]=parseInt(day[i], 10) || 0;
                };
                day[1]-= 1;
                day= new Date(Date.UTC.apply(Date, day));
                if(!day.getDate()) return NaN;
                if(p[5]){
                    tz= (parseInt(p[5], 10)*60);
                    if(p[6]) tz+= parseInt(p[6], 10);
                    if(p[4]== '+') tz*= -1;
                    if(tz) day.setUTCMinutes(day.getUTCMinutes()+ tz);
                }
                return day;
            }
            return NaN;
        }
        // remove test:
        //if(isNaN(D)) alert('ISO Date Not implemented');
        //else alert('ISO Date Not correctly implemented');
    }
    else{
        Date.fromISO= function(s){
            return new Date(s);
        }
        // remove test:
        //alert('ISO Date implemented');
    }
})()