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
* The Auteur is the automaton that manages the differences between different raconteur implementations.
* It behaves as a singleton (per thread/process), and is modeled after gulp and winston.
* @class Auteur
###
auteur = exports

# expose version
require('pkginfo')(module, 'version')

###
PROPERTY DEFINITIONS!
###

# ! - "_" non-enumerable properties should begin with an underscore, for clarity

###
# ! - "___" this is our object definition object
      Which gives us access to these methods:
      ___.define
      ___.mutable
      ___.private
      ___.public
      ___.writable
      ___.constant
      ___.protected
###
___ = require('./parkplace').scope auteur

___.constant 'fs', fs

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
    _FILE_CONFIG: 'raconfig.json'
}

# assign each constant
# we use _.assign here to make sure that our original
# classConstants variable doesn't mutate
_({}).assign(classConstants).merge(fileConstants).each (value, key)->
    ___.constant key, value

###*
* classes constant, for array convenience
* @property _classes
* @type Array
###
___.constant '_classes', _.values classConstants

# let's get eventy (alias all EventEmitter methods as our own)
_(emitter).methods().each (fxName)->
    # all as non-configurable public methods
    ___.public fxName, ()->
        emitter[fxName].apply auteur, arguments

###*
* Checks a given classname against our _classes listing
* @method isValidClass
* @param {String} className - a possibly valid class name
* @return {Boolean} validClass
###
___.public 'isValidClass', (className)->
    unless _.isString className
        return false
    return _.contains auteur._classes, className.toLowerCase()

###*
* As the name suggests, throws an error if given not-a-class
* @method throwOnInvalidClass
* @param {String} x - a possibly valid class name
* @private
###
___.private 'throwOnInvalidClass', (x)->
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
___.public 'create', (kind)->
    @throwOnInvalidClass kind
    args = _.rest arguments
    console.log ">> auteur create #{kind}"
    methodName = '_create' + capitalize kind
    if @[methodName]?
        return @[methodName].apply @, args
    throw new Error "Expected #{methodName} to be valid method."

___.private '_createProject', ()->
    console.log "createProject", arguments

___.private '_createPost', ()->
    console.log "createPost", arguments

___.private '_createAuthor', ()->
    console.log "createAuthor", arguments

___.private '_createBookmark', ()->
    console.log "createBookmark", arguments

___.public 'testDirectory', ()->

___.public 'test', (kind)->
    @throwOnInvalidClass kind
    console.log @config, "<<< this that json?"
    args = _.rest arguments
    console.log ">> auteur test #{kind}"
    methodName = '_test' + capitalize kind
    if @[methodName]?
        return @[methodName].apply @, args
    throw new Error "Expected #{methodName} to be valid method."

___.private '_testProject', ()->
    console.log "testProject", arguments

___.private '_testPost', ()->
    console.log "testPost", arguments

___.private '_testAuthor', ()->
    console.log "testAuthor", arguments

___.private '_testBookmark', ()->
    console.log "testBookmark", arguments

___.mutable 'exclusions', [
    'node_modules'
    '.git'
    '.svn'
]

###*
* The default list of files to announce when traversing
* @property fileHooks
* @public
###
___.mutable 'fileHooks', [
    auteur._FILE_CONFIG
]

###*
* Our default set of configurable options.
* @property _CONFIG_CONSTANT
* @private
###
___.constant '_CONFIG_CONSTANT', {
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

###*
* A mutable version of our _CONFIG_CONSTANT
* @property config
* @public
###
___.mutable 'config', _.assign {}, auteur._CONFIG_CONSTANT

___.private '_generateConfig', (where)->
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

___.private '_readConfig', (file)->
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

___.public 'rebuild', (path, exclusions, announce)->
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

___.private '_announceFileMatches', (data)->
    self = @
    {announce, file, dir, filename, stat} = data
    dirParts = dir.split '/'
    emitFileMatch = (pointer)->
        info = {
            path: file
            name: filename
            stat: stat
        }
        if pointer?
            info.match = pointer
            self.emit "file:match:#{pointer}", info
        self.emit 'file:match', info
        self.emit "file:match:#{filename}", info
    emitDirectoryMatch = (pointer)->
        last = _.last dirParts
        info = {
            path: file
            name: dir
            dir: last
            stat: stat
        }
        if pointer?
            info.match = pointer
            self.emit "directory:match:#{pointer}", info
        self.emit 'directory:match', info
        self.emit "directory:match:#{last}", info
    isDirectory = stat.isDirectory()
    _(announce).each (announcement)->
        if announcement is filename
            emitFileMatch announcement
            return
        # wildcard matching
        if -1 < announcement.indexOf '*'
            parts = announcement.split '.'
            # we have a wildcard
            unless isDirectory # files only
                currDir = _.last dirParts
                if announcement is currDir + '/*'
                    emitDirectoryMatch currDir
                    emitFileMatch currDir + '/*'
                    return
                if parts.length > 1                    
                    if parts[1]?
                        if announcement is currDir + '/*.' + parts[1]
                            emitDirectoryMatch currDir
                            emitFileMatch currDir + '/*.' + parts[1]
                        if announcement is "*." + parts[1]
                            emitFileMatch '*.' + parts[1]
                            return
                    if parts[0]?
                        if announcement is parts[0] + ".*"
                            emitFileMatch parts[0] + ".*"
                            return

###*
* Recursively walk a directory, while announcing the existence of specified files (optionally filterable)
* @method _spiderDirectory
* @private
* @param {String} location - the directory to walk
* @param {Array} exclusions - an array of file/dirnames to exclude from the walk
* @param {Array} announce - an array of file/dirnames to announce when found, matches file wildcards (*) but not globs (**) or directory wildcards (dir/*) (yet)
###
___.private '_spiderDirectory', (location, exclude=[], announce=[])->
    self = @
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
                    if err
                        d.nay err
                        return
                    self._announceFileMatches {
                        announce: announce
                        file: file
                        dir: dir
                        filename: filename
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