// jshint eqnull: true
(function($) {
    "use strict";

    this.subway = this.subway || {};
    // subway namespace
    // ===================
    //
    // A collection of functions for application logic and front-end utilities.

    function Cons(first, more) {
        this._first = first;
        this._more  = more;
    }

    // ISeq
    Cons.prototype.first = function() {
        return this._first;
    };

    // ISeq
    Cons.prototype.more = function() {
        if (this._more == null)
            return List.EMPTY;
        return this._more;
    };

    // ISeq
    Cons.prototype.next = function() {
        return this.more().seq();
    };

    Cons.prototype.count = function() {
        return 1 + this.subway.count(this._more);
    };

    // Seqable
    Cons.prototype.seq = function() {
        return this;
    };

    function List(first, rest, count) {
        this._first = first;
        this._rest = rest == null ? null : rest;
        this._count = count == null ? 1 : count;
    }

    List.EMPTY = new List(null, null, 0);

    List.prototype.first = function() {
        return this._first;
    };

    List.prototype.next = function() {
        if (this._count === 1) return null;
        return this._rest;
    };


    List.prototype.peek = List.prototype.first;

    List.prototype.pop = function() {
        if (this._rest == null) return List.EMPTY;
        return this._rest;
    };

    List.prototype.count = function() {
        return this._count;
    };

    List.prototype.cons = function(x) {
        return new List(x, this, this._count + 1);
    };

    List.prototype.reduce = function(f, init) {
        var ret, s;
        if (arguments.length === 1) {
            ret = this.first();
            for (s = this.next(); s != null; s = s.next()) {
                ret = f.call(null, ret, s.first());
            }
            return ret;
        } else if (arguments.length === 2) {
            ret = f.call(null, init, this.first());
            for (s = this.next(); s != null; s = s.next()) {
                ret = f.call(null, ret, s.first());
            }
            return ret;
        } else {
            throw new Error('reduce should have at least 1 argument');
        }
    };

    this.subway.List = List;

    function list() {
        var i, l = List.EMPTY;
        for (i = arguments.length - 1; i >= 0; i--) {
            l = l.cons(arguments[i]);
        }
        return l;
    }

    this.subway.list = list;

    function isList(x) {
        return x instanceof List;
    }

    this.subway.isList = isList;

    function LazyList(seq, fn) {
        this.fn = fn == null ? null : fn;
        this._seq = seq == null ? null : seq;
        this._sv = null;
    }

    LazyList.prototype = Object.create(List.prototype);

    LazyList.prototype.sval = function() {
        if (this.fn != null) {
            this._sv = this.fn.call();
            this.fn = null;
        }
        if (this._sv != null) {
            return this._sv;
        }
        return this._seq;
    };

    LazyList.prototype.seq = function() {
        this.sval();
        if (this._sv != null) {
            var ls = this._sv;
            this._sv = null;
            while (ls instanceof LazyList) {
                ls = ls.sval();
            }
            this._seq = ls;
        }
        return this._seq;
    };

    LazyList.prototype.count = function() {
        var c = 0,
            s;
        for (s = this; s != null; s = s.next()) {
            c++;
        }
        return c;
    };

    LazyList.prototype.cons = function(x) {
        return cons(x, this.seq());
    };

    LazyList.prototype.first = function() {
        this.seq();
        if (this._seq == null) {
            return null;
        }
        return this._seq.first();
    };

    LazyList.prototype.next = function() {
        this.seq();
        if (this._seq == null) {
            return null;
        }
        return this._seq.next();
    };

    this.subway.LazyList = LazyList;

    function lazyList(fn) {
        return new LazyList(null, fn);
    }

    this.subway.lazyList = lazyList;

    function isLazyList(x) {
        return x instanceof LazyList;
    }

    this.subway.isLazyList = isLazyList;

    function isSeq(x) {
        return x != null && x.first && x.next;
    }

    // TODO: add array
    function isSeqable(x) {
        return x != null && (isArrayLike(x) || Object.prototype.toString.call(x.seq) === '[object Function]');
    }

    function seq(x) {
        if (x == null) return List.EMPTY;
        else if (x.seq) {
            return x.seq();
        }
        else if (isArrayLike(x)) {
            var i, s = List.EMPTY;
            for (i = x.length - 1; i >= 0; i--) {
                s = s.cons(x[i]);
            }
            return s;
        }
        else {
            console.log(x);
            throw new Error('value is not seqable');
        }
    }

    function first(xs) {
        if (isSeq(xs)) return xs.first();
        else if (isSeqable(xs)) {
            return seq(xs).first();
        } else {
            throw new Error('not a sequence');
        }
    }

    function rest(xs) {
        var val;
        if (isSeq(xs)) {
            val = xs.next();
        }
        else if (isSeqable(xs)) {
            val = seq(xs).next();
        }
        else {
            throw new Error('not a sequence');
        }
        if (val == null) return List.EMPTY;
        else             return val;
    }

    function next(xs) {
        if (isSeq(xs)) {
            return xs.next();
        }
        else if (isSeqable(xs)) {
            return seq(xs).next();
        }
        else {
            throw new Error('not a sequence');
        }
    }

    function cons(x, xs) {
        if (xs == null) return new List(x);
        else if (isSeq(xs)) {
            return new Cons(x, xs);
        }
        else {
            return new Cons(x, seq(xs));
        }
    }

    function take(n, xs) {
        if (arguments.length !== 2) {
            throw new Error(str('Wrong number of arguments expected: 2, got: ', arguments.length));
        }
        return lazyList(function() {
            if (n >= 0) {
                return cons(first(xs), take(n - 1, rest(xs)));
            } else {
                return null;
            }
        });
    }

    this.subway.take = take;

    function drop(n, xs) {
        if (arguments.length !== 2) {
            throw new Error(str('Wrong number of arguments expected: 2, got: ', arguments.length));
        }
        var s = seq(xs);
        return lazyList(function() {
            var n_ = n;
            while (s != null && n_ >= 0) {
                n_--;
                s = rest(s);
            }
            return s;
        });
    }

    this.subway.drop = drop;

    function N(n) {
        var n_ = n == null ? 0 : n;
        return cons(n_, lazyList(function() {
            return N(n_ + 1);
        }));
    }

    this.subway.N = N;

    // convert an array-like object (any object with a length prototype
    // and numeric indexes) into an array
    //
    // ArrayLike -> Array
    function toArray(obj) {
        return Array.prototype.slice.call(obj);
    }

    // concatenates strings
    //
    // () -> EmptyString
    // Any* -> String
    function str() {
        return Array.prototype.slice.call(arguments).join('');
    }

    // Collection -> Boolean
    function isEmpty(val) {
        return val == null || val.length === 0;
    }

    function isArray(x) {
        return Object.prototype.toString.call(x) === '[object Array]';
    }

    this.subway.isArray = isArray;

    function isString(x) {
        return Object.prototype.toString.call(x) === '[object String]';
    }

    this.subway.isString = isString;

    function isFunction(x) {
        return Object.prototype.toString.call(x) === '[object Function]';
    }

    this.subway.isFunction = isFunction;

    function isObject(x) {
        return Object.prototype.toString.call(x) === '[object Object]';
    }

    this.subway.isObject = isObject;

    function isBoolean(x) {
        return Object.prototype.toString.call(x) === '[object Boolean]';
    }

    this.subway.isBoolean = isBoolean;

    function isNumber(x) {
        return Object.prototype.toString.call(x) === '[object Number]';
    }

    this.subway.isNumber = isNumber;

    function isNull(x) {
        return x === null;
    }

    this.subway.isNull = isNull;

    function isUndefined(x) {
        return x === void(0);
    }

    this.subway.isUndefined = isUndefined;

    function exists(x) {
        return x != null;
    }

    this.subway.exists = exists;

    function isArrayLike(x) {
        return x != null && isNumber(x.length);
    }

    this.subway.isArrayLike = isArrayLike;

    // cooerce strings into numbers
    //
    // String -> Number
    function num(s) {
        if (s == null) return 0;
        else           return 1 * s;
    }
    
    this.subway.num = num;

    // use a reducing function to combine a collection of
    // values into a new value
    //
    // Function -> Collection -> Any
    // Function -> Collection -> Any -> Any
    function reduce(fn, xs, memo) {
        var x;
        if (arguments.length === 2) {
            memo = first(xs);
            xs   = rest(xs);
        }
        else if (arguments.length === 3) {
            // do nothing
        }
        else {
            throw new Error(str('Wrong number of arguments, expected: 2 or 3, got: ', arguments.length));
        }
        while (xs != null) {
            x    = first(xs);
            memo = fn.call(null, memo, x);
            xs   = next(xs);
        }
        return memo;
    }

    // execute a function on a collection of values an return a
    // array of the results.
    //
    // Function -> Collection -> LazyList
    function map(fn, xs) {
        if (arguments.length !== 2) {
            throw new Error(str('Wrong number of arguments, expected: 2, got: ', arguments.length));
        }
        return lazyList(function(){
            return cons(fn.call(null, first(xs)), map(fn, rest(xs)));
        });
    }

    // Object -> String
    function fmtParams(obj) {
        var a = [], i, k;
        var keys = Object.getOwnPropertyNames(obj);
        for (i = 0; i < keys.length; i++) {
            k = keys[i];
            if (obj[k] != null) a.push(str(k, '=', encodeURI(obj[k])));
        }
        return a.join('&');
    }

    function fmtStyles(name, value) {
        if (typeof value === 'string') {
            return str(name, '="', value, '"');
        } else {
            var i, k, val, a = [];
            var keys = Object.getOwnPropertyNames(value);
            for (i = 0; i < keys.length; i++) {
                k = keys[i];
                val = value[k];
                a.push(str(k, ':', val));
            }
            return str(name, '="', a.join(';'), '"');
        }
    }

    var ATTR_PROC = {
        style: fmtStyles
    };

    // Object -> String
    // TODO: need to escape JS strings
    function fmtAttrs(obj) {
        var i, k, val, a = [];
        var keys = Object.getOwnPropertyNames(obj);
        for (i = 0; i < keys.length; i++) {
            k = keys[i];
            val = obj[k];
            if (ATTR_PROC[k]) a.push(ATTR_PROC[k](k, val));
            else {
                if (val === true) a.push(k);
                else if (val === false) {
                    continue;
                } else {
                    a.push(str(k, '="', obj[k], '"'));
                }
            }
        }
        return a.join(' ');
    }

    // Array -> String
    function renderTagList(exps) {
        return reduce(function(s, exp) {
            return str(s, html(exp));
        }, exps, "");
    }

    // generates HTML from JavaScript data stuctures
    //
    // Any -> String
    function html(exp) {
        var tag, attrs, rest;
        if (exp == null) return '';
        else if (typeof exp === 'string' || typeof exp === 'number') {
            return str(exp);
        } else if (typeof exp === 'boolean') {
            if (exp === false) return 'false';
            else return 'true';
        } else if (typeof exp === 'object') {
            if (exp instanceof Array) {
                if (exp.length === 0) return '';
                else if (typeof exp[0] !== 'string') {
                    return renderTagList(exp);
                }
                // evaluate as a tag
                else {
                    tag = exp[0];
                    // evaluate as a tag with attributes
                    if (typeof exp[1] === 'object' && exp[1].__proto__.__proto__ == null) {
                        attrs = exp[1];
                        rest = exp.slice(2);
                        return str('<', tag, ' ', fmtAttrs(attrs), '>', renderTagList(rest), '</', tag, '>');
                    }
                    // evaluate as a tag without attributes
                    else {
                        rest = exp.slice(1);
                        return str('<', tag, '>', renderTagList(rest), '</', tag, '>');
                    }
                }
            }
            else {
                return str(exp);
            }
        } else {
            throw new Error(str("'", exp, "' is an invalid expression"));
        }
    }

    function renderTo(elem, exp) {
        return $(elem).html(html(exp));
    }

    function appendTo(elem, exp) {
        return $(elem).append(html(exp));
    }

    var SYMBOLS = {
        '\\.': '__DOT__',
        '\\/': '__SLASH__',
        '\\:': '__COLON__',
        '\\?': '__QUEST__',
        '\\!': '__BANG__'
    };

    function encodePunct(val) {
        var keys = Object.keys(SYMBOLS);
        var s = val;
        for (var i = 0; i < keys.length; ++i) {
            s = s.replace(new RegExp(keys[i], 'g'), SYMBOLS[keys[i]]);
        }
        return s;
    }

    var print = console.log.bind();

    function unhandledException(e) {
        console.error(e);
        console.log(e.stack);
        throw new Error('Unhandled Exception: ', e.message);
    }

    var http = {};
    http.request = function(method, url, data) {
        return new Promise(function(resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.addEventListener('load', function(event) {
                resolve.call(null, event.target.response, event);
            });
            xhr.addEventListener('error', function(event) {
                reject.call(null, event);
            });
            console.log(method, ' - ', url);
            xhr.open(method, url);
            if (data) xhr.send(data);
            else xhr.send(null);
        }).catch(unhandledException);
    };

    // exports
    this.subway.html = html;
    this.subway.renderTo = renderTo;
    this.subway.appendTo = appendTo;
    this.subway.encodePunct = encodePunct;
    this.subway.str = str;
    this.subway.toArray = toArray;
    this.subway.map = map;
    this.subway.reduce = reduce;
    this.subway.fmtParams = fmtParams;
    this.subway.http = http;
    this.subway.print = print;

}).call(window, jQuery);
