###
#!/usr/bin/env node
###

"use strict"
Liftoff = require 'liftoff'
interpret = require 'interpret'
auteur = require './auteur'
fs = auteur.fs

chalk = require 'chalk'

cliPackage = require '../package'

_ = require 'lodash'
tar = require 'tar'
fstream = require 'fstream'

# gimme a scope
___ = require('parkplace').scope auteur

# this object will take the form {longFlag: shortFlag}
___.constant '_CLI_FLAGS',
    cwd: 'w'
    "no-color": 'n'
    make: 'm'
    test: 't'
    convert: 'c'
    help: 'h'
    compress: 'z'

crayon = {}
_(chalk.styles).each (fx, method)->
    crayon[method] = (x)->
        return _.toArray(arguments).join ' '

grayscale = (flags)->
    if flags['no-color']?
        chalk = crayon
    return chalk

###
AUTEUR
  * -w, --cwd <path> - use path as current working directory
  * -n, --no-color - use output without colors
  * -m, --make <project> - create 
  * -t, --test - test current directory
  * -c, --convert <file> - convert file
  * -z, --compress - compress posts and assets
  * -h, --help - this content
###
displayHelp = (chalk)->
    console.log chalk.underline 'AUTEUR'
    console.log " ", chalk.gray "-w, --cwd <path>", chalk.white "- use path as current working directory"
    console.log " ", chalk.red "-n, --no-color", chalk.white "- use output without colors"
    console.log " ", chalk.magenta "-m, --make <project>", chalk.white "- create "
    console.log " ", chalk.cyan "-t, --test", chalk.white "- test current directory"
    console.log " ", chalk.yellow "-c, --convert <file>", chalk.white "- convert file"
    console.log " ", chalk.magenta "-z, --compress <file>", chalk.white "- compress posts and assets"
    console.log " ", chalk.green "-h, --help", chalk.white "- the content you're currently reading"
    return

___.constant '_VALID_COMMANDS', [
    'create'
    'test'
    'convert'
    'compress'
    'uncompress'
]

___.secret '_compressPosts', (path, fileOut)->
    compressed = @compress path, fileOut
    compressed.then (o)->
        console.log "Wrote file: ", o
    , (e)->
        console.log "Threw error: ", e
        if e.stack?
            console.log e.stack

___.secret '_uncompressPosts', (fileIn, pathOut)->
    console.log "uncompress posts....", arguments
    self = @
    cwd = process.cwd()
    fileIn = cwd + '/' + fileIn
    pathOut = cwd
    fs.realpath fileIn, (err, path)->
        uncompressed = self.uncompress fileIn, pathOut
        uncompressed.then (o)->
            console.log "Untarred file: ", o
        , (e)->
            console.log "Threw error: ", e
            if e.stack?
                console.log e.stack
        console.log "it's over!"


___.secret '_readFlags', (flags)->
    unless flags?
        return
    cwd = process.cwd()
    chalk = grayscale flags
    if flags._? and 0 < _.size flags._
        # find a valid instruction
        instruction = _(flags._).filter((x)->
            match = _.contains auteur._VALID_COMMANDS, x
            return match
        ).first()
        @log "the instruction is:", chalk.red instruction
        if instruction?
            args = _.rest flags._
            @log "the args are", args
            if instruction is 'test'
                instruction = 'testDirectory'
            if instruction is 'compress'
                instruction = '_compressPosts'
                args = [cwd + '/posts', 'posts.racontar']
            if instruction is 'uncompress'
                instruction = '_uncompressPosts'
            if auteur[instruction]?
                auteur[instruction].apply auteur, args
            return

    if flags.help?
        return displayHelp chalk
    else if flags.create?
        @log 'create?'
        return
    else if flags.convert?
        @log 'convert?'
        return
    else if flags.test?
        @log 'test?'
        return
    return displayHelp chalk


___.secret '_readFlagsWithContext', (flags, context)->
    self = @
    d = @postpone()
    grayscale flags
    unless context?
        return @_readFlags flags
    {config, env} = context
    @config = config
    # fileMatcher = (match)->
    #     console.log match, 'matchypatchy filatchy'
    # @on 'file:match', fileMatcher

    postMatcher = (post)->
        console.log post.path, '(found post)'

    @on 'directory:match:posts', postMatcher

    exclusions = [
        'node_modules'
        '.git'
        '.svn'
    ]
    announce = [
        'posts/*'
        'assets/*'
    ]
    web = @_spiderDirectory env.cwd, exclusions, announce
    web.then (o)->
        d.yay o
    , (e)->
        d.nay e
        console.log "Error during flag reading.", e
        if e.stack?
            console.log e.stack
    self._readFlags flags
    return d

###*
* A method to reduce the given flags to valid sets 
* @method _normalizeFlags
* @private
* @param {Object} flagObject - an object containing the flags
* @return {Object} normalizedFlagObject - all of the flags will be long now.
###
___.secret '_normalizeFlags', (flagObject)->
    self = @
    flagConstant = @_CLI_FLAGS
    keys = _.keys flagConstant
    flags = _.values flagConstant
    inverted = _.invert flagConstant
    # normalize all the flags
    # regardless of whether the long or short flag was used
    mapFlagsToLong = (value, key)->
        if key is '_'
            return {_: value}
        if _.contains(keys, key) or _.contains(flags, key)
            normal = {}
            longFlag = inverted[key]
            unless longFlag?
                longFlag = inverted[flagConstant[key]]
            normal[longFlag] = value
            return normal
        return null
    reducer = (carrier, value, index, carried)->
        carrier[_(value).keys().first()] = _(value).values().first()
        return carrier
    normalized = _(flagObject).map mapFlagsToLong
                              .compact()
                              .reduce reducer, {}
    return normalized

argv = auteur._normalizeFlags require('minimist') process.argv.slice 2

launchSequence = {
    name: 'auteur'
    extension: interpret.jsVariants
    configName: 'raconfig'
}

process.env.INIT_CWD = process.cwd()


failed = false
process.once 'exit', (code)->
    if (code is 0) and failed
        process.exit 1

cli = new Liftoff launchSequence

onRequire = (name, module)->
    console.log "loading external module", name

onRequireFail = (name, err)->
    console.log "Unable to load", name, err
    if err.stack?
        console.log err.stack

launchcode = {
    cwd: argv.cwd
}

processArguments = (env)->
    # instance = auteur
    grayscale argv
    unless env.modulePath
        console.log chalk.red "Local auteur not found in"
        console.log chalk.magenta env.cwd, "\n"
        console.log chalk.cyan 'Try running: npm i auteur'
        return process.exit 1
    instance = require env.modulePath
    context = null
    if env.configPath and env.configPath?
        context =
            config: require env.configPath
            env: env
    unless context?
        console.log chalk.red "Unable to load raconfig.json file."
        console.log chalk.magenta "Read documentation here: https://github.com/brekk/auteur"
        return process.exit 1

    proflag = instance._readFlagsWithContext argv, context
    process.nextTick ()->
        proflag.then (o)->
            console.log "oh damn", o
            process.exit 1
        , (e)->
            console.log "Error during flag reading", e
            if e.stack?
                console.log e.stack
            process.exit 1
    # if @configPath
    #     process.chdir @configBase
    #     console.log "Setting current working directory", @configBase
    # else
    #     console.log "No .raconfig file found. Run `auteur create config` to generate one."
    #     process.exit(1)

cli.on 'require', onRequire
   .on 'requireFail', onRequireFail
   .launch launchcode, processArguments

module.exports = cli