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

glob = require 'simple-glob'

###*
* The Auteur is the automaton that manages the differences between different raconteur implementations.
* It behaves as a singleton (per thread/process), and is modeled after gulp and winston.
* @class Auteur
###
auteur = module.exports = {}

# expose version
require('pkginfo')(module, 'version')

###
PROPERTY DEFINITIONS!
###

# ! - "_" non-enumerable properties should begin with an underscore, for clarity

###
# ! - "___" this is our object definition object
      Which gives us access to these methods:
      ___.define (objectDefition wrapper)
      ___.mutable
      ___.writable
      ___.secret
      ___.open
      ___.writable
      ___.constant
      ___.protected
###
pp = require 'parkplace'

___ = pp.scope auteur

___.constant 'fs', fs

___.constant 'promise', promise

___.secret 'postpone', ()->
    d = new Deferred()
    d.yay = _.once d.resolve
    d.nay = _.once d.reject
    return d

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
    # all as non-configurable readable methods
    ___.readable fxName, ()->
        emitter[fxName].apply auteur, arguments

###*
* Checks a given classname against our _classes listing
* @method isValidClass
* @param {String} className - a possibly valid class name
* @return {Boolean} validClass
###
___.readable 'isValidClass', (className)->
    unless _.isString className
        return false
    return _.contains auteur._classes, className.toLowerCase()

###*
* As the name suggests, throws an error if given not-a-class
* @method throwOnInvalidClass
* @param {String} x - a possibly valid class name
* @private
###
___.secret 'throwOnInvalidClass', (x)->
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

___.readable 'timecode', (time)->
    unless time?
        time = Date.now()
    forcePrependZeroes = (z)->
        if z < 10
            return '0' + z
        return '' + z
    x = new Date()
    zone = _.last x.toString().split(' ')
    y = x.getFullYear()
    o = forcePrependZeroes x.getMonth() + 1
    d = forcePrependZeroes x.getDate()
    h = forcePrependZeroes x.getHours()
    m = forcePrependZeroes x.getMinutes()
    s = forcePrependZeroes x.getSeconds()
    out = "#{o}#{d}#{y}-#{h}:#{m}:#{s} #{zone}"
    return out

___.open 'log', ()->
    console.log.apply console, [@timecode() + ' -'].concat _.toArray arguments

###*
* A validator and single location for calling a bunch of possible sub-functions
* @method create
* @param {String} kind - create what kinda thing?
###
___.readable 'create', (kind)->
    @throwOnInvalidClass kind
    args = _.rest arguments
    console.log ">> auteur create #{kind}"
    methodName = '_create' + capitalize kind
    if @[methodName]?
        return @[methodName].apply @, args
    throw new Error "Expected #{methodName} to be valid method."

___.secret '_createProject', ()->
    console.log "createProject", arguments

___.secret '_createPost', ()->
    console.log "createPost", arguments

___.secret '_createAuthor', ()->
    console.log "createAuthor", arguments

___.secret '_createBookmark', ()->
    console.log "createBookmark", arguments

___.readable 'testDirectory', ()->

___.readable 'test', (kind)->
    @throwOnInvalidClass kind
    console.log @config, "<<< this that json?"
    args = _.rest arguments
    console.log ">> auteur test #{kind}"
    methodName = '_test' + capitalize kind
    if @[methodName]?
        return @[methodName].apply @, args
    throw new Error "Expected #{methodName} to be valid method."

___.secret '_testProject', ()->
    console.log "testProject", arguments

___.secret '_testPost', ()->
    console.log "testPost", arguments

___.secret '_testAuthor', ()->
    console.log "testAuthor", arguments

___.secret '_testBookmark', ()->
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

___.secret '_generateConfig', (where)->
    d = @postpone()
    filename = where + '/.raconfig'
    self = @
    fs.writeFile filename, JSON.stringify(@config, null, 4), (err)->
        if err?
            d.nay err
        self.emit 'file:written', filename
        self.emit 'file:written:config', true
        d.yay filename
    return d

___.secret '_readConfig', (file)->
    d = @postpone()
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

___.readable 'rebuild', (path, exclusions, announce)->
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

___.readable 'uncompress', (fileIn, pathOut)->
    d = @postpone()
    unless fileIn?
        d.nay throw new Error "Expected filename to be given."
    else
        onError = (err)->
            d.nay err
            console.log "An error occurred while uncompressing.", err
            if err.stack?
                console.log err.stack
        onEnd = ()->
            outcome = fileIn + ' uncompressed.'
            console.log outcome
            d.yay outcome
        options = {
            path: pathOut
        }
        extractor = tar.Extract options
                       .on 'error', onError
                       .on 'end', onEnd
        fs.createReadStream fileIn
          .on 'error', onError
          .pipe extractor
    return d

___.readable 'compress', (path, fileOut)->
    d = @postpone()
    unless fileOut?
        d.nay throw new Error "Expected filename to be given."
    else
        if -1 < fileOut.indexOf '.'
            fileParts = fileOut.split '.'
            fileParts[0] += '-' + @timecode()
            fileOut = fileParts.join '.'
        else
            fileOut += '-' + @timecode()
        directoryDestination = fs.createWriteStream fileOut
        onError = (e)->
            d.nay e
            console.log "this error occurred.", e
            if e.stack?
                console.log e.stack
        onSuccess = ()->
            d.yay fileOut

        packer = tar.Pack {noProprietary: true}
                    .on 'error', onError
                    .on 'end', onSuccess

        fstream.Reader {path: path, type: "Directory"}
               .on 'error', onError
               .pipe packer
               .pipe directoryDestination
    return d

___.secret '_announceFileMatches', (data)->
    self = @
    {announce, file, dir, filename, stat} = data
    dirParts = dir.split '/'
    emitFileMatch = (pointer, match)->
        info = {
            path: file
            name: filename
            stat: stat
        }
        if pointer?
            info.pointer = pointer
            self.emit "file:match:#{pointer}", info
        if match?
            info.match = match
            self.emit "file:match:#{match}", info
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
        x = glob announcement
        if 0 < _.size x
            _(x).each (match)->
                currDir = _.last dirParts
                emitDirectoryMatch currDir
                unless isDirectory
                    emitFileMatch match, announcement

###*
* Recursively walk a directory, while announcing the existence of specified files (optionally filterable)
* @method _spiderDirectory
* @private
* @param {String} location - the directory to walk
* @param {Array} exclusions - an array of file/dirnames to exclude from the walk
* @param {Array} announce - an array of file/dirnames to announce when found, matches file wildcards (*) but not globs (**) or directory wildcards (dir/*) (yet)
###
___.secret '_spiderDirectory', (location, exclude=[], announce=[])->
    self = @
    d = @postpone()

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