#!/usr/bin/env jruby
# hello_world.rb 

require 'java'
java_import 'HelloWorld'

HelloWorld.world()
HelloWorld.earth()
HelloWorld.moon()
HelloWorld.somebody('Dewayne')
HelloWorld.people( ['John', 'Paul', 'George', "Ringo"] )


puts <<~EOS

###########################################
## Now lets do it to the jRuby generated class HelloWorldRuby

EOS

java_import 'HelloWorldRuby'

HelloWorldRuby.world()
HelloWorldRuby.earth()
HelloWorldRuby.moon()
HelloWorldRuby.somebody('Dewayne')
HelloWorldRuby.people( ['John', 'Paul', 'George', "Ringo"] )
