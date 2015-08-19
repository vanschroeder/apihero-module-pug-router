###*
# RequestHandler
# Route Handler File
# Generated by Jade-Router for ApiHero 
###
_         = require 'lodash'
path      = require 'path'

class RouteHandler
  render: (res, model) ->
    res.render @config.template_file, JSON.parse(JSON.stringify model), (e, html) ->
      console.log e if e?
      res.send html
  requestHandler: (req, res, next) ->
    # attempts to determine name for `Query Method` defaults to 'find'
    funcName = @config.queryMethod or 'find'
    # attempts to determine `Collection Name` defaults to config name for route
    collectionName = unless (name = @config.collectionName || "").length then null else name
    # placeholds the result object
    model = 
      meta: []
      session: req.session
    # tests for Collection Name
    unless collectionName? and @_app_ref.models.hasOwnProperty collectionName
      # renders page and returns if no Collection Name was defined
      return @render res, model
    # performs Query Execution
    execQuery = (colName, funName, q, cB) =>
      # tests for existance of query arguments defintion
      if q.hasOwnProperty 'arguments'
        # captures values of argument properties
        args = _.values(q.arguments)
        # pushes callback into argument values array
        args.push cB
        # applies arguments array with callback upon Collection Operation
        return @_app_ref.models[colName][funName].apply @, args
      # invokes Collection Operation with Query and Callback only
      @_app_ref.models[colName][funName] q, cB
    # processes query from Configuration and Request Query and Params Object
    processQuery = (c_query, callback) =>
      # holds `name` of Response Object Element
      elName = if c_query.hasOwnProperty('name') then c_query.name else 'results'
      # holds `name` of Collection to perform Operations against
      colName = if c_query.hasOwnProperty('collectionName') then c_query.collectionName else collectionName
      # holds `name` of Operation to perform against Collection
      funName = if c_query.hasOwnProperty('queryMethod') then c_query.queryMethod else funcName or 'find'
      # checks for Required Arguments property set on Query config
      if c_query.query.hasOwnProperty('required') and _.isArray(c_query.query.required)
        # holds missing arguments that were required
        missing = undefined
        # checks for existance of all required arguments
        if (missing = _.difference c_query.query.required, _.keys req.query).length > 0
          return res.status(400).send "required argument '#{missing[0]}' was missing from query params"
      # tests for arguments element on Query Settings Object
      if c_query.query.hasOwnProperty 'arguments'
        # loops on each arguments defined
        for arg of c_query.query.arguments
          `arg = arg`
          # skips unprocessable arguments
          if !c_query.query.arguments[arg]
            continue
          # tests for argument values that match `:` or `?`
          if (param = c_query.query.arguments[arg].match /^(\:|\?)+([a-zA-Z0-9-_]{1,})+$/)?
            # if value matched `:`, that is a ROUTE PARAMETER such as /:id and is applied against request.params
            # if value matched `?`, that is a REQUEST QUERY PARAMETER such as ?param=value and is applied against request.query
            c_query.query.arguments[arg] = req[if param[1] == ':' then 'params' else 'query']["#{param[2]}"]
      # wraps passed calllback for negotiation
      cB = (e, res) ->
        # invokes callback and returns in case of error
        return callback(e) if e?
        # placeholds results object
        o = {}
        # applies defined Result Element Name withj results
        o[elName] = res
        # passes formatted results to callback
        callback null, o
      # invokes Query Execution Method with Collection, Operation Method and Query
      execQuery colName, funName, c_query.query, cB
    # tests if configured Query element is an `Array`
    if _.isArray @config.query
      # defines completion method
      done = _.after(@config.query.length, (e, resultset) =>
        if e != null
          console.log e
          return res.sendStatus 500
        # invokes render with result set
        @render res, resultset
      )
      # loops on each configured query passed
      _.each @config.query, (q) ->
        # inokes Query Processing method
        processQuery _.cloneDeep(q), (e, res) ->
          # invokes done each iteration
          done e, _.extend(model, res)
    else
      # is a single query configuration -- process directly
      processQuery _.cloneDeep(@config.query), (e, resultset) ->
        if e != null
          console.log e
          return res.sendStatus 500
        return res.status(404).send("document not found") unless resultset?
        # invokes render with result set
        @render res, _.extend(model, resultset)
  # Routeing Module Entry Point
  constructor: (@filePath, @_app_ref)->
    try 
      @config = require path.join "#{path.dirname @filePath}", "#{path.basename @filePath}.json"
    catch e
      console.log e
      process.exit 1
    # tests for RegExp based route as denoted by a `rx:` prefix
    route = if (s = (@config.route || '').split('rx:')).length > 1 then new RegExp(s.pop()) else @config.route
    # applies the Route and Handler Method to a GET Request 
    @_app_ref.get route, (req, res, next) =>
      if @config.hasOwnProperty('secured') and @config.secured and !req.accessToken
        res.render 'forbidden.jade', { meta: [] }, (e, html) ->
          console.log e if e?
          res.send html
      else
        @requestHandler req, res, next
module.exports = RouteHandler