// hello_ratpack.groovey
// To execute this web app do:
//      groovey hello_ratpack.groovey

@Grapes([
  @Grab('io.ratpack:ratpack-groovy:1.3.3'),
  @Grab('org.slf4j:slf4j-simple:1.7.12')
])

import static ratpack.groovy.Groovy.ratpack

ratpack {
    handlers {
        get {
            render "Hello World!"
        }
        get(":name") {
            render "Hello $pathTokens.name!"
        }
    }
}
