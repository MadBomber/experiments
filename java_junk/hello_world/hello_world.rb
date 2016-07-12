# hello_world.rb


require 'java'
java_import 'HelloWorld'

HelloWorld.main()
HelloWorld.world()
HelloWorld.earth()
HelloWorld.moon()
HelloWorld.somebody('Dewayne')
HelloWorld.people( ['John', 'Paul', 'George', "Ringo"] )


__END__

require 'awesome_print'

ap HelloWorld.methods

