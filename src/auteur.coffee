(->
    "use strict"

    ###
    DEPENDENCIES
    ###
    _ = require 'lodash'

    events = require 'events'
    emitter = new events.EventEmitter()

    promise = require 'promised-io'
    Deferred = promise.Deferred

    fs = require 'fs'

    postpone = ()->
        d = new Deferred()
        d.yay = _.once d.resolve
        d.nay = _.once d.reject
        return d

    ###*
    * The Auteur is the automaton that manages the differences between different implementations.
    * It behaves as a singleton (per thread/process), and is modeled after gulp and winston.
    * @class Auteur
    ###
    auteur = exports

    # expose version
    require('pkginfo')(module, 'version')

    ###
    PROPERTY DEFINITIONS!
    ###

    # non-enumerable properties should begin with an underscore, for clarity

    # our define function is a simple wrapper around an Object.defineProperty call
    # and we reuse this function in each of the double-underscored methods below
    __define = (prop, value, settings, onObject)->
        unless onObject?
            onObject = auteur
        settings = _.assign {
            enumerable: true
            writable: true
            configurable: true
        }, settings
        if value?
            settings.value = value
        Object.defineProperty onObject, prop, settings

    # e: 1, w: 1, c: 1
    __mutable = (prop, value)->
        __define prop, value

    # e: 0, w: 1, c: 0
    __private = (prop, value)->
        settings = {
            enumerable: false
            writable: true
            configurable: false
        }
        __define prop, value, settings

    # e: 1, w: 0, c: 0
    __public = (prop, value)->
        settings = {
            enumerable: true
            writable: false
            configurable: false
        }
        __define prop, value, settings

    # e: 1, w: 1, c: 0
    __writable = (prop, value)->
        settings = {
            enumerable: true
            writable: true
            configurable: false
        }
        __define prop, value, settings

    # e: 0, w: 0, c: 0
    __constant = (prop, value)->
        settings = {
            enumerable: false
            writable: false
            configurable: false
        }
        __define prop, value, settings

    # e: 0, w: 0, c: 1
    __protected = (prop, value)->
        settings = {
            enumerable: false
            writable: false
            configurable: true
        }

    # this is for things that are scoped out of any context
    # enumerable or otherwise (and are therefore truly private)
    __hiddenContext = {}
    __hidden = (prop, value)->
        unless __hiddenContext[prop]?
            __define prop, value, {}, __hiddenContext
            return true
        return false

    # if there's a hidden property, use this function to find it
    __lookupHidden = (key)->
        if __hiddenContext[key]?
            return __hiddenContext[key]
        return undefined

    ###
    CONSTANTS
    ###

    classConstants = {
        _CLASS_PROJECT: 'project'
        _CLASS_POST: 'post'
        _CLASS_AUTHOR: 'author'
        _CLASS_BOOKMARK: 'bookmark'
    }

    fileConstants = {
        _FILE_CONFIG: '.raconfig'
    }

    # assign each constant
    _(classConstants).merge(fileConstants).each (value, key)->
        __constant key, value

    ###*
    * classes constant, for array convenience
    * @property _classes
    * @type Array
    ###
    __constant '_classes', _.values classConstants

    # let's get eventy (alias all EventEmitter methods as our own)
    _(emitter).methods().each (fxName)->
        # all as non-configurable public methods
        __public fxName, ()->
            emitter[fxName].apply auteur, arguments

    ###*
    * Checks a given classname against our _classes listing
    * @method isValidClass
    * @param {String} className - a possibly valid class name
    * @return {Boolean} validClass
    ###
    __public 'isValidClass', (className)->
        unless _.isString className
            return false
        return _.contains auteur._classes, className.toLowerCase()

    ###*
    * As the name suggests, throws an error if given not-a-class
    * @method throwOnInvalidClass
    * @param {String} x - a possibly valid class name
    * @private
    ###
    __private 'throwOnInvalidClass', (x)->
        unless x?
            throw new TypeError "Expected class to be defined."
        unless _.isString x
            throw new TypeError "Expected class to be string."
        unless @isValidClass x
            throw new TypeError "Expected class to be one of [ #{auteur._classes.join(', ')} ]."

    # convenience method, not part of object spec
    capitalize = (x)->
        if _.isString x
            first = x.substr(0, 1).toUpperCase()
            rest = x.substr(1)
            capped = first + rest
            return capped
        return x

    ###*
    * A validator and single location for calling a bunch of possible sub-functions
    * @method create
    * @param {String} kind - create what kinda thing?
    ###
    __public 'create', (kind)->
        @throwOnInvalidClass kind
        args = _.rest arguments
        console.log ">> auteur create #{kind}"
        methodName = '_create' + capitalize kind
        if @[methodName]?
            return @[methodName].apply @, args
        throw new Error "Expected #{methodName} to be valid method."

    __private '_createProject', ()->
        console.log "createProject", arguments

    __private '_createPost', ()->
        console.log "createPost", arguments

    __private '_createAuthor', ()->
        console.log "createAuthor", arguments

    __private '_createBookmark', ()->
        console.log "createBookmark", arguments

    __public 'test', (kind)->
        @throwOnInvalidClass kind
        args = _.rest arguments
        console.log ">> auteur test #{kind}"
        methodName = '_test' + capitalize kind
        if @[methodName]?
            return @[methodName].apply @, args
        throw new Error "Expected #{methodName} to be valid method."

    __private '_testProject', ()->
        console.log "testProject", arguments

    __private '_testPost', ()->
        console.log "testPost", arguments

    __private '_testAuthor', ()->
        console.log "testAuthor", arguments

    __private '_testBookmark', ()->
        console.log "testBookmark", arguments

    __mutable 'exclusions', [
        'node_modules'
        '.git'
        '.svn'
    ]

    __mutable 'fileHooks', [
        auteur._FILE_CONFIG
    ]

    __constant '_CONFIG_CONSTANT', {
        project: ''
        user: {
            name: ''
            fullname: ''
        }
        directories: {
            posts: 'posts'
            assets: 'assets'
        }
    }

    __mutable 'config', _.assign auteur._CONFIG_CONSTANT, {}

    # this object will take the form {longFlag: shortFlag}
    __constant '_FLAGS', {
        project: 'p'
        posts: 'o'
        assets: 'a'
    }

    __private '_normalizeFlags', (flagObject)->
        self = @
        keys = _.keys @_FLAGS
        flags = _.values @_FLAGS
        inverted = _.invert @_FLAGS
        normalized = _(flagObject).map((value, key)->
            normal = {}
            if _.contains(keys, key) or _.contains(flags, key)
                longFlag = inverted[key]
                unless longFlag?
                    longFlag = inverted[self._FLAGS[key]]
                normal[longFlag] = value
            return normal
        ).compact().reduce (carrier, value, index, carried)->
            carrier[_(value).keys().first()] = _(value).values().first()
            return carrier
        , {}

    __public 'invoke', (settings)->
        self = @
        if settings.project?
            self.config.project = settings.project
        if settings.posts?
            self.config.posts = settings.posts
        if settings.assets?
            self.config.assets = settings.assets
        console.log "invocation vacation", self


    __public 'cli', ()->
        argv = require('minimist') process.argv.slice 2
        argv = @_normalizeFlags argv
        return auteur.invoke argv

    __private '_generateConfig', (where)->
        d = postpone()
        filename = where + '/.raconfig'
        self = @
        fs.writeFile filename, JSON.stringify(@config, null, 4), (err)->
            if err?
                d.nay err
            self.emit 'file:written', filename
            self.emit 'file:written:config', true
            d.yay filename
        return d

    __private '_readConfig', (file)->
        d = postpone()
        self = @
        fs.readFile file.path, 'utf8', (err, obj)->
            if err
                d.nay err
                return
            data = JSON.parse obj
            console.log "this is the data in the config object!", data
            self.config = data
            d.yay data
            return
        return d

    __public 'rebuild', (path, exclusions, announce)->
        unless path?
            path = process.cwd()
        unless exclusions?
            exclusions = @exclusions
        unless announce?
            announce = []
        self = @
        announce = _.union announce, @fileHooks
        @once 'file:match', (match)->
            if match.name is self._FILE_CONFIG
                console.log "found a magic config file!", match
                self._readConfig(match).then (data)->
                    console.log "the files are in the computer?!?", data
                , (err)->
                    console.log "the files aren't in the computer", err
                    if err.stack?
                        console.log err.stack
        return @_spiderDirectory path, exclusions, announce

    ###*
    * 
    * @method _spiderDirectory
    * @param {String} location - the directory to walk
    * @param {Array} exclusions - an array of file/dirnames to exclude from the walk
    * @param {Array} announce - an array of file/dirnames to announce when found
    ###
    __private '_spiderDirectory', (location, exclude, announce)->
        self = @
        unless exclude?
            exclude = []
        unless announce?
            announce = []

        d = postpone()

        walk = (dir, done)->
            results = []
            fs.readdir dir, (err, list)->
                if err
                    return done err
                list = _.pull.apply _, [list].concat exclude
                pending = list.length
                unless pending
                    return done null, results
                _(list).each (file)->
                    filename = file
                    file = "#{dir}/#{file}"
                    fs.stat file, (err, stat)->
                        if _.contains announce, filename
                            self.emit 'file:match', {
                                path: file
                                name: filename
                                stat: stat
                            }
                            self.emit "file:match:#{filename}", {
                                path: file
                                name: filename
                                stat: stat
                            }
                        if stat?.isDirectory?()
                            walk file, (err, res)->
                                if err?
                                    return done err
                                results = results.concat res
                                unless --pending
                                    return done null, results
                        else
                            results.push file
                            unless --pending
                                return done null, results

        absolutePathWalk = (err, path)->
            if err?
                return d.nay err
            walk path, (err, out)->
                if err
                    return d.nay err
                return d.yay out
        fs.realpath location, absolutePathWalk
        return d

    return exports

).call(this)