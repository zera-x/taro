var subway;
(function (subway) {

    var _ = subway;

    var Connection = (function () {

        function Connection(endpoint) {
            this.endpoint = endpoint;
        }

        Connection.prototype.url = function (path, params) {
            if (params) {
                var paramStr = _.fmtParams(params);
                return _.str(this.endpoint, "/api", path, "?", paramStr);
            }
            else {
                return _.str(this.endpoint, "/api", path);
            }
        };

        Connection.prototype.decodeMsg = function (data) {
            var res = JSON.parse(data);
            if (!res)
                throw new Error("there was an error decoding a message from the server");
            if (res.status === 'error') {
                throw new Error(_.str("Server Error: ", res.message));
            }
            else {
                return res.data;
            }
        };

        Connection.prototype.request = function (method, path, params, data) {
            var that = this;
            return _.http.request(method, this.url(path, params), data, this).then(function (data) {
                return that.decodeMsg(data);
            });
        };

        Connection.prototype.get = function (path, params) {
            return this.request("GET", path, params);
        };

        Connection.prototype.post = function (path, data) {
            return this.request("POST", path, undefined, data ? data : undefined);
        };

        Connection.prototype.repos = function () {
            return this.get('/repos');
        };
        
        Connection.prototype.createRepo = function (name) {
            return this.post(_.str('/repos/', name));
        };

        return Connection;
    }());

    subway.Connection = Connection;

    var Database = (function () {
        function Database(conn, name) {
            this.conn = conn;
            this.name = name;
        }

        var DBS = {};
        Database.get = function (conn, name) {
            DBS[name] = DBS[name] || new Database(conn, name);
            return DBS[name];
        };

        Database.prototype.connection = function () { return this.conn; };
        Database.prototype.name = function () { return this.name; };

        Database.prototype.entity = function(id) {
            if(!id) throw new Error('entity id is required');
            return this.conn.get(_.str("/repos/", this.name, "/entity/", id));
        };

        Database.prototype.transact = function (txs) {
            if (!_.isArray(txs)) throw new Error('transaction should be an Array of Arrays or Objects (Maps)');
            for (var i = 0; i < txs.length; i++) {
                if (_.isArray(txs[i])) {
                    if (txs[i].length !== 4) throw new Error('an assertion/retraction should have 4 and only 4 elements');
                }
            }
            return this.conn.post(_.str('/repos/', this.name, '/transaction'), JSON.stringify(txs));
        };

        Database.prototype.query = function(q, p, psize) {
            return this.conn.get(_.str('/repos/', this.name), {q: q, p: p, page_size: psize});
        };

        return Database;

    }());

    subway.connect = function(endpoint) {
        return new Connection(endpoint);
    };

    subway.db = function(conn, name) {
        return new Database(conn, name);
    };

    subway.transact = function(db, txs) {
        return db.transact(txs);
    };

    subway.entity = function(db, id) {
        return db.entity(id);
    };

    subway.query = function(db, q, p, psize) {
        return db.query(q, p, psize);
    };

    subway.createRepo = function(conn, name) {
        return conn.createRepo(name).then(function(dbname) {
            return new Database(conn, dbname);
        });
    };

    subway.repos = function(conn) {
        return conn.repos();
    };

    subway.endpoint = function() {
        var loc = window.location;
        var url = _.str('http://', loc.hostname, ':', loc.port, subway.ROOT_URL);
        if (url.endsWith('/')) {
            return url.slice(0, url.length - 1);
        }
        return url;
    };

    subway.path = function(path) {
        var end = subway.endpoint();
        if (path == null) return end;
        if (_.isString(path)) {
            return _.str(end, '/', path);
        }
        else if (_.isArray(path)) {
            var last = path[path.length - 1];
            if (_.isObject(last)) {
                var front = path.slice(0, path.length - 1);
                return _.str(end, '/', front.join('/'), '?', _.fmtParams(last));
            }
            else {
                return _.str(end, '/', path.join('/'));
            }
        }
        else {
            throw new Error('invalid path type');
        }
    };

})(subway || (subway = {}));
