_ = require 'lodash'

###*
* The Auteur is the automaton that manages the differences between different implementations.
* It behaves as a singleton (per thread/process), and is modeled after gulp and winston.
* @class Auteur
###
auteur = exports

# expose version
require('pkginfo')(module, 'version')

# cli implementation
auteur.cli = ()->
   console.log "ostensibly, the CLI method should enable some kind of differing functionality"
   return auteur

# non-enumerable properties should begin with an underscore, for clarity
classConstants = {
   _CLASS_PROJECT: 'project'
   _CLASS_POST: 'post'
   _CLASS_AUTHOR: 'author'
   _CLASS_BOOKMARK: 'bookmark'
}
_.each classConstants, (prop, key)->
   Object.defineProperty auteur, key, {
       enumerable: false
       writable: false
       configurable: false
       value: prop
   }

Object.defineProperty auteur, '_classes', {
   enumerable: false
   writable: false
   configurable: false
   value: [
       auteur._CLASS_PROJECT
       auteur._CLASS_POST
       auteur._CLASS_AUTHOR
       auteur._CLASS_BOOKMARK
   ]
}
auteur.isValidClass = (className)->
   unless _.isString className
       throw new TypeError "Expected className to be string."
   return _.contains auteur._classes, className.toLowerCase()

auteur.create = (kind)->
   args = _.rest arguments
   unless @isValidClass kind
       throw new TypeError "Expected kind to be one of [ #{auteur._classes.join(', ')} ]."
   console.log ">> auteur create #{kind}"
   first = kind.substr(0, 1).toUpperCase()
   rest = kind.substr(1)
   name = first + rest
   return @['create' + name].apply @, args

auteur.createProject = ()->
   console.log "createProject", arguments

auteur.createPost = ()->
   console.log "createPost", arguments

auteur.createAuthor = ()->
   console.log "createAuthor", arguments

auteur.createBookmark = ()->
   console.log "createBookmark", arguments


auteur.test = (kind)->
   args = _.rest arguments
   unless @isValidClass kind
       throw new TypeError "Expected kind to be one of [ #{auteur._classes.join(', ')} ]."
   console.log ">> auteur test #{kind}"

auteur.convert = (postName)->
   console.log ">> auteur convert #{postName}"
