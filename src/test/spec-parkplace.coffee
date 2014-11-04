assert = require 'assert'
should = require 'should'
_ = require 'lodash'
pp = require '../lib/parkplace'

(->
    "use strict"
    try
        fixture = require './fixtures/parkplace.json'
        boardwalk = fixture.base
        describe 'Parkplace', ()->
            describe '.define', ()->
                simple = {}
                it 'should be a method of Parkplace', ()->
                    pp.define.should.be.ok
                    pp.define.should.be.a.Function
                it 'should define mutable properties with no other instructions', ()->
                    zip = fixture.define.zip
                    pp.define zip.prop, zip.value, null, simple
                    simple.should.have.property zip.prop
                    simple.hasOwnProperty(zip.prop).should.be.ok
                    simple[zip.prop].should.equal zip.value
                    (->
                        pp.define zip.prop, Math.random()*10, null, simple
                    ).should.not.throwError
                it 'should throw an error if no scope object is given and .scope is not called', ()->
                    (->
                        pp.define 'test', Math.random() * 10
                    ).should.throwError
                it 'should not throw an error if no scope object is given and .scope has been called', ()->
                    (->
                        zap = {}
                        pzap = pp.scope zap
                        pzap.define 'test', Math.random() * 10
                    ).should.not.throwError
            zoningCommittee = null
            describe '.scope', ()->
                it 'should create a definer with a given scope', ()->
                    zoningCommittee = pp.scope boardwalk
                    zoningCommittee.should.be.ok
                    zoningCommittee.should.have.properties 'define', 'mutable', 'private', 'writable', 'public', 'constant', 'protected'
                    zoningCommittee.should.not.have.properties 'hidden', 'lookupHidden', 'scope'
                it 'should add a .get and a .has method to the scoped definer', ()->
                    zoningCommittee.should.have.properties 'has', 'get'
                    pp.should.not.have.properties 'has', 'get'

            describe '.mutable', ()->
                it 'should throw an error if .scope has not been called', ()->
                    (->
                        pp.mutable 'test', 100
                    ).should.throwError
            describe '.private', ()->
                # e: 0, w: 1, c: 0
            describe '.public ', ()->
                # e: 1, w: 0, c: 0
            describe '.writable', ()->
                # e: 1, w: 1, c: 0
            describe '.constant', ()->
                # e: 0, w: 0, c: 0
            describe '.protected', ()->
                # e: 0, w: 0, c: 1
            describe '.hidden', ()->

            describe '.lookupHidden', ()->

    catch e
        console.log "Error during testing!", e
        if e.stack?
            console.log e.stack
).call @