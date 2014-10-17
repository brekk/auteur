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

    fs = require 'promised-io/fs'

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
    define = (prop, value, settings, onObject)->
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
        define prop, value

    # e: 0, w: 1, c: 0
    __private = (prop, value)->
        settings = {
            enumerable: false
            writable: true
            configurable: false
        }
        define prop, value, settings

    # e: 1, w: 0, c: 0
    __public = (prop, value)->
        settings = {
            enumerable: true
            writable: false
            configurable: false
        }
        define prop, value, settings

    # e: 1, w: 1, c: 0
    __writable = (prop, value)->
        settings = {
            enumerable: true
            writable: true
            configurable: false
        }
        define prop, value, settings

    # e: 0, w: 0, c: 0
    __constant = (prop, value)->
        settings = {
            enumerable: false
            writable: false
            configurable: false
        }
        define prop, value, settings

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
            define prop, value, {}, __hiddenContext
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

    # assign each constant
    _(classConstants).each (value, key)->
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

    __private '_spiderDirectory', (location)->
        d = new Deferred()
        d.yay = _.once d.resolve
        d.nay = _.once d.reject
        failHook = (e)->
            d.nay e
        path = fs.absolute location
        fs.stat(path).then (stats)->
            unless stats.isDirectory()
                d.nay new Error "Expected to be given a directory."
            fs.readdir(path).then (files)->
                simple = {}
                _(files).each (file)->
                    local = {
                        stat: fs.stat(file)
                    }
                    simple[file] = local

                d.yay simple
            , failHook
        , failHook


        return d




    return exports

).call(this)