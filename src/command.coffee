###
#!/usr/bin/env node
###

"use strict"
Liftoff = require 'liftoff'
interpret = require 'interpret'
auteur = require './auteur'

chalk = require 'chalk'

cliPackage = require '../package'
_ = require 'lodash'

# gimme a scope
___ = require('./parkplace').scope auteur

# this object will take the form {longFlag: shortFlag}
___.constant '_CLI_FLAGS',
    "no-color": 'n'
    make: 'm'
    test: 't'
    convert: 'c'
    help: 'h'

crayon = {}
_(chalk.styles).each (fx, method)->
    crayon[method] = (x)->
        return _.toArray(arguments).join ' '
###
AUTEUR
  * -n, --no-color - use output without colors
  * -m, --make <project> - create 
  * -t, --test - test current directory
  * -c, --convert <file> - convert file
  * -h, --help - this content
###
displayHelp = (chalk)->
    console.log chalk.underline 'AUTEUR'
    console.log " ", chalk.red "-n, --no-color", chalk.white "- use output without colors"
    console.log " ", chalk.magenta "-m, --make <project>", chalk.white "- create "
    console.log " ", chalk.cyan "-t, --test", chalk.white "- test current directory"
    console.log " ", chalk.yellow "-c, --convert <file>", chalk.white "- convert file"
    console.log " ", chalk.green "-h, --help", chalk.white "- the content you're currently reading"
    return

___.private '_readFlag', (flags)->
    if flags?['no-color']?
        chalk = crayon
    if flags?.help?
        return displayHelp chalk
    else if flags?.create?
        console.log 'create?'
        return
    else if flags?.convert?
        console.log 'convert?'
        return
    return displayHelp chalk
    

###*
* A method to reduce the given flags to valid sets 
* @method _normalizeFlags
* @private
* @param {Object} flagObject - an object containing the flags
* @return {Object} normalizedFlagObject - all of the flags will be long now.
###
___.private '_normalizeFlags', (flagObject)->
    self = @
    flagConstant = @_CLI_FLAGS
    keys = _.keys flagConstant
    flags = _.values flagConstant
    inverted = _.invert flagConstant
    # normalize all the flags
    # regardless of whether the long or short flag was used
    mapFlagsToLong = (value, key)->
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

cli.on 'require', onRequire
   .on 'requireFail', onRequireFail

cli.launch {
    cwd: argv.cwd
}, (env)->
    instance = auteur
    # instance = require env.modulePath
    process.nextTick ()->
        instance._readFlag argv
        process.exit 1
    # if @configPath
    #     process.chdir @configBase
    #     console.log "Setting current working directory", @configBase
    # else
    #     console.log "No .raconfig file found. Run `auteur create config` to generate one."
    #     process.exit(1)

module.exports = cli