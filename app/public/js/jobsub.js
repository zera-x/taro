var jobsub = (function() {
    "use strict";

    var _ = subway;

    function pluck(prop) {
        return function(xs) {
            return xs.map(function(x) { return x[prop]; });
        };
    }

    function Atom(val, validator) {
        this.val = val;
        this.validator = validator;
        this.watches = {};
    }

    Atom.prototype.deref = function() {
        return this.val;
    };

    Atom.prototype.addWatch = function(k, fn) {
        this.watches[k] = fn;
        return this;
    };

    Atom.prototype.removeWatch = function(k) {
        delete this.watches[k];
        return this;
    };

    function processWatches(watches, ref, newVal) {
        var w, k, i, keys = Object.getOwnPropertyNames(watches);
        for (i = 0; i < keys.length; i++) {
            k = keys[i];
            w = watches[k];
            w.call(ref, k, ref, ref.val, newVal);
        }
    }

    Atom.prototype.reset = function(val) {
        processWatches(this.watches, this, val);
        this.val = val;
        return this;
    };

    Atom.prototype.swap = function(fn) {
        return this.reset(fn.call(this, this.val));
    };

    function reset (atom) {
        return function(val) {
            atom.reset(val);
            return val;
        };
    }

    var db = _.db(_.connect(_.endpoint()), 'jobs');

    var results = new Atom(null);

    results.addWatch('results-update', function(key, ref, vold, vnew) {
        console.log(key, vold, vnew);
        _.renderTo('.jobsub-report', ['ul', vnew.map(function(row){
            return ['li', ['a', {href: _.path(['admin', 'repos', 'jobs', 'entity', row.e])}, row.e]];
        })]);
    });

    function page(name, p, psize) {
        _.query(db, _.str('[:find ?e :where [?e :job.name "', name, '"]]'), p, psize)
            .then(reset(results))
            .then(_.print);
    }


    $(document).ready(function() {
        _.renderTo(
            '#main',
            [['h1', "Jobsub Conversion Progress"],
             ['form.form-inline', {action: '#'},
              ['div', {class: 'form-group'},
               ['input', {class: 'form-control', type: 'text', name: 'job-name'}]],
              ['button', {type: 'submit', class: 'btn btn-primary', onclick: "jobsub.search(jQuery('[name=job-name]').val())"}, 'Search']],
             ['div', {class: 'jobsub-report'}]]);
        //page("szupd_startdate", 1);
    });

    return {
        search: page
    };
}());
