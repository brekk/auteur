assert = require 'assert'
should = require 'should'
_ = require 'lodash'
pp = require '../lib/parkplace'

(->
    "use strict"
    try
        fixture = require './fixtures/parkplace.json'
        boardwalk = fixture.base
        mutableDef = fixture.definitions.mutable
        privateDef = fixture.definitions.private
        zoningCommittee = null
        # reusable tests
        itShouldBarfIf = (sentence, fx, negative=false)->
            unless _.isString sentence
                throw new TypeError "Gimme a string for a sentence."
            unless _.isFunction fx
                throw new TypeError "Quit wasting time and gimme a function."
            negate = if negative then ' not' else ''
            it "should#{negate} throw an error if #{sentence}", ()->
                if negative
                    fx.should.not.throwError
                else
                    fx.should.throwError

        itShouldNotBarfIf = (s, f, n=true)->
            itShouldBarfIf s, f, n

        itShouldMaintainScope = ()->
            itShouldBarfIf '.scope has not been called', ()->
                pp.mutable 'test', 100
                return

        describe 'Parkplace', ()->

            describe '.define', ()->

                simple = {}
                
                it 'should be a method of Parkplace', ()->
                    pp.define.should.be.ok
                    pp.define.should.be.a.Function
                
                it 'should define mutable properties with no other instructions', ()->
                    pp.define mutableDef.prop, mutableDef.value, null, simple
                    simple.should.have.property mutableDef.prop
                    simple.hasOwnProperty(mutableDef.prop).should.be.ok
                    simple[mutableDef.prop].should.equal mutableDef.value
                    (->
                        pp.define mutableDef.prop, Math.random()*10, null, simple
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
                # e: 1, w: 1, c: 1
                itShouldMaintainScope()

                it 'should allow properties to be defined', ()->
                    zoningCommittee.mutable mutableDef.prop, mutableDef.value
                    boardwalk[mutableDef.prop].should.be.ok

                itShouldNotBarfIf 'a property is redefined', ()->
                    zoningCommittee.mutable mutableDef.prop, 'zopzopzop'
                
                it 'should allow property definitions to be redefined', ()->
                    zoningCommittee.mutable mutableDef.prop, 'zopzopzop'
                    boardwalk[mutableDef.prop].should.be.ok
                    boardwalk[mutableDef.prop].should.eql 'zopzopzop'

                it 'should allow property values to be changed', ()->
                    hip3 = 'hiphiphip'
                    boardwalk[mutableDef.prop] = hip3
                    boardwalk[mutableDef.prop].should.eql hip3
                
            describe '.private', ()->
                # e: 0, w: 1, c: 0
                itShouldMaintainScope()

                it 'should hide variables from enumerable scope', ()->
                    zoningCommittee.private privateDef.prop, privateDef.value
                    Object.keys(boardwalk).should.not.containEql privateDef.prop
                    boardwalk.propertyIsEnumerable(privateDef.prop).should.eql false


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