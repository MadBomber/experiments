/*
  File: HelloWorldJava.java

  Usage:
    export CLASSPATH=.
    javac HelloWorld.java       // compile into HelloWorld.class
    javac HelloWorldJava.java   // compile into HelloWorldJava.class
    java HelloWorldJava         // executes the #main method of the HelloWorldJava.class
*/

public class HelloWorldJava {

  public static void main(String[]args) {

    HelloWorld hw = new HelloWorld();

    hw.world();
    hw.earth();
    hw.moon();
    hw.somebody("Dewayne");
    hw.people( new String[]{"John", "Paul", "George", "Ringo"} );

/*  CLASSPATH needs to have the jruby junk on it
*/
    HelloWorldRuby hwr = HelloWorldRuby();

    hwr.world();
    hwr.earth();
    hwr.moon();
    hwr.somebody("Dewayne");
    hwr.people( new String[]{"John", "Paul", "George", "Ringo"} );


  } // end public static void main() {

} // end public class HelloWorldJava {
