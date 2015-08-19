// Generated by CoffeeScript 1.9.3

/**
 * RequestHandler
 * Route Handler File
 * Generated by Jade-Router for ApiHero
 */
var RouteHandler, _, path;

_ = require('lodash');

path = require('path');

RouteHandler = (function() {
  RouteHandler.prototype.render = function(res, model) {
    return res.render(this.config.template_file, JSON.parse(JSON.stringify(model)), function(e, html) {
      if (e != null) {
        console.log(e);
      }
      return res.send(html);
    });
  };

  RouteHandler.prototype.requestHandler = function(req, res, next) {
    var collectionName, done, execQuery, funcName, model, name;
    funcName = this.config.queryMethod || 'find';
    collectionName = !(name = this.config.collectionName).length ? null : name;
    model = {
      meta: [],
      session: req.session
    };
    if (!((collectionName != null) && this._app_ref.models.hasOwnProperty(collectionName))) {
      return render(res, model);
    }
    execQuery = function(colName, funName, q, cB) {
      var args;
      if (q.hasOwnProperty('arguments')) {
        args = _.values(q["arguments"]);
        args.push(cB);
        return this._app_ref.models[colName][funName].apply(this, args);
      }
      return this._app_ref.models[colName][funName](q, cB);
    };
    ({
      processQuery: function(c_query, callback) {
        var arg, cB, colName, elName, funName, missing, param;
        elName = c_query.hasOwnProperty('name') ? c_query.name : 'results';
        colName = c_query.hasOwnProperty('collectionName') ? c_query.collectionName : collectionName;
        funName = c_query.hasOwnProperty('queryMethod') ? c_query.queryMethod : funcName || 'find';
        if (c_query.query.hasOwnProperty('required') && _.isArray(c_query.query.required)) {
          missing = void 0;
          if ((missing = _.difference(c_query.query.required, _.keys(req.query))).length > 0) {
            return res.status(400).send("required argument '" + missing[0] + "' was missing from query params");
          }
        }
        if (c_query.query.hasOwnProperty('arguments')) {
          for (arg in c_query.query["arguments"]) {
            arg = arg;
            if (!c_query.query["arguments"][arg]) {
              continue;
            }
            if ((param = c_query.query["arguments"][arg].match(/^(\:|\?)+([a-zA-Z0-9-_]{1,})+$/)) != null) {
              c_query.query["arguments"][arg] = req[param[1] === ':' ? 'params' : 'query']["" + param[2]];
            }
          }
        }
        cB = function(e, res) {
          var o;
          if (e != null) {
            return callback(e);
          }
          o = {};
          o[elName] = res;
          return callback(null, o);
        };
        return execQuery(colName, funName, c_query.query, cB);
      }
    });
    if (_.isArray(this.config.query)) {
      done = _.after(this.config.query.length, function(e, resultset) {
        if (e !== null) {
          console.log(e);
          return res.sendStatus(500);
        }
        return this.render(res, resultset);
      });
      return _.each(this.config.query, function(q) {
        return this.processQuery(_.cloneDeep(q), function(e, res) {
          return done(e, _.extend(model, res));
        });
      });
    } else {
      return this.processQuery(_.cloneDeep(this.config.query), function(e, resultset) {
        if (e !== null) {
          console.log(e);
          return res.sendStatus(500);
        }
        return this.render(res, _.extend(model, resultset));
      });
    }
  };

  function RouteHandler(filePath, _app_ref) {
    var e, route, s;
    this.filePath = filePath;
    this._app_ref = _app_ref;
    try {
      this.config = require(path.join("" + (path.dirname(this.filePath)), (path.basename(this.filePath)) + ".json"));
    } catch (_error) {
      e = _error;
      console.log(e);
      process.exit(1);
    }
    route = (s = (this.config.route || '').split('rx:')).length > 1 ? new RegExp(s.pop()) : this.config.route;
    this._app_ref.get(route, function(req, res, next) {
      if (this.config.hasOwnProperty('secured') && this.config.secured && !req.accessToken) {
        return res.render('forbidden.jade', {
          meta: []
        }, function(e, html) {
          if (e != null) {
            console.log(e);
          }
          return res.send(html);
        });
      } else {
        req.session.userId = req.accessToken.userId;
        return this.requestHandler(req, res, next);
      }
    });
  }

  return RouteHandler;

})();

module.exports = RouteHandler;