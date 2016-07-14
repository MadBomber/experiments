/*
  File: HelloWorldJava.java

  Usage:
    export CLASSPATH=.
    javac HelloWorld.java       // compile into HelloWorld.class
    javac HelloWorldJava.java   // compile into HelloWorldJava.class
    java HelloWorldJava         // executes the #main method of the HelloWorldJava.class
*/

// import org.apache.bsf.BSFManager;
// import org.apache.bsf.util.IOUtils;

/*
import org.jruby.Ruby;
import org.jruby.javasupport.Java;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.GlobalVariable;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.FileReader;
import java.io.IOException;
*/

public class HelloWorldJava {

  public static void main(String[]args) {

    HelloWorld hw = new HelloWorld();

    hw.world();
    hw.earth();
    hw.moon();
    hw.somebody("Dewayne");
    hw.people( new String[]{"John", "Paul", "George", "Ringo"} );

/*  FIXNE: CLASSPATH needs to have the jruby junk on it
           Its more that just the CLASSPATH; there is something
           from apache called the bean scripting framework that
           looks like it needs to be used.  See this URL for an
           example:
            https://github.com/jruby/jruby/wiki/JRubyAndJavaCodeExamples#Java_calling_JRuby

    HelloWorldRuby hwr = HelloWorldRuby();

    hwr.world();
    hwr.earth();
    hwr.moon();
    hwr.somebody("Dewayne");
    hwr.people( new String[]{"John", "Paul", "George", "Ringo"} );
*/

  } // end public static void main() {

} // end public class HelloWorldJava {
