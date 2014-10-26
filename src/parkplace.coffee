# It's called Park Place, because that's a good definition of a property

"use strict"
_ = require 'lodash'

exports = exports || {}

# our define function is a simple wrapper around an Object.defineProperty call
# and we reuse this function in each of the methods below .scope
exports.define = (prop, value, settings, onObject)->
    settings = _.assign {
        enumerable: true
        writable: true
        configurable: true
    }, settings
    if value?
        settings.value = value
    # for convenience, the onObject passes through the scope function's wrapper
    # so that you don't have to establish a separate variable for it
    unless _.isObject onObject
        scope = exports.lookupHidden('scope')
        if scope?
            onObject = scope
    unless _.isObject onObject
        throw new TypeError "Attempted to define property on non-object. Consider using parkplace.scope(context)."
    Object.defineProperty onObject, prop, settings

exports.scope = (ref)->
    scopedDefinition = _.assign {}, exports
    # make it un-rescopable, 'cause that's confusing
    delete scopedDefinition.scope
    delete scopedDefinition.hidden
    delete scopedDefinition.lookupHidden
    exports.hidden 'scope', ref
    return scopedDefinition

# Now, the definitions:

# e: 1, w: 1, c: 1
exports.mutable = (prop, value)->
    exports.define prop, value

# e: 0, w: 1, c: 0
exports.private = (prop, value)->
    settings = {
        enumerable: false
        writable: true
        configurable: false
    }
    exports.define prop, value, settings

# e: 1, w: 0, c: 0
exports.public = (prop, value)->
    settings = {
        enumerable: true
        writable: false
        configurable: false
    }
    exports.define prop, value, settings

# e: 1, w: 1, c: 0
exports.writable = (prop, value)->
    settings = {
        enumerable: true
        writable: true
        configurable: false
    }
    exports.define prop, value, settings

# e: 0, w: 0, c: 0
exports.constant = (prop, value)->
    settings = {
        enumerable: false
        writable: false
        configurable: false
    }
    exports.define prop, value, settings

# e: 0, w: 0, c: 1
exports.protected = (prop, value)->
    settings = {
        enumerable: false
        writable: false
        configurable: true
    }

# this is for things that are scoped out of any context
# enumerable or otherwise (and are therefore truly private)
hiddenContext = {}
exports.hidden = (prop, value, force=false)->
    if !hiddenContext[prop]? or force
        exports.define prop, value, {}, hiddenContext
        return true
    return false

# if there's a hidden property, use this function to find it
exports.lookupHidden = (key)->
    if hiddenContext[key]?
        return hiddenContext[key]
    return undefined

module.exports = exports
return exports