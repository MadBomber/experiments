#!/usr/bin/env jython
# hello_world.py

import HelloWorld

HelloWorld.world()
HelloWorld.earth()
HelloWorld.moon()
HelloWorld.somebody('Dewayne')
HelloWorld.people( ['John', 'Paul', 'George', "Ringo"] )

print '\n###########################################'
print '## Now lets do it to the jRuby generated class HelloWorldRuby'
print '## MUST have the jRuby jars etc in the CLASSPATH\n'

import HelloWorldRuby

HelloWorldRuby.world()
HelloWorldRuby.earth()
HelloWorldRuby.moon()
HelloWorldRuby.somebody('Dewayne')
HelloWorldRuby.people( ['John', 'Paul', 'George', "Ringo"] )
