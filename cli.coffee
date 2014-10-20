#!/usr/bin/env node
(->
    "use strict"
    Liftoff = require 'liftoff'

    launchSequence = {
        name: 'auteur'
    }

    onRequire = (name, module)->
        console.log "loading external module", name

    onRequireFail = (name, err)->
        console.log "Unable to load", name, err
        if err.stack?
            console.log err.stack

    Auteur = new Liftoff(launchSequence).on 'require', onRequire
                                        .on 'requireFail', onRequireFail

    Auteur.launch ()->
        if @configPath
            process.chdir @configBase
            console.log "Setting current working directory", @configBase
        else
            console.log "No .raconfig file found. Run `auteur create config` to generate one."
            process.exit(1)
            
).call(this)